defmodule RandomUsers.MinNumber do
  @moduledoc """
  A gen server that upon startup generates a random number, and keeps the time of the previous call to get_users

  Every minute (and upon startup) it gets itself a new random number (0-100) and updates all the users in the database
  to with new random values for the "points"

  The get_users call fetches at most two users from the DB that have a property of having their points larger than the 
  min_number stored in the GenServer, it also updates the stored timestamp

  """
  use GenServer
  import Ecto.Query, only: [from: 2]

  defstruct min_number: 0, timestamp: nil

  @impl true
  def init(min_number) do
    Process.send_after(self(), :update, 0 * 1000)
    {:ok, %__MODULE__{min_number: min_number, timestamp: nil}}
  end

  def start_link(opts) do
    min_number = Enum.random(0..100)
    GenServer.start_link(__MODULE__, min_number, opts)
  end

  def get_users(pid) do
    GenServer.call(pid, :get_users)
  end

  @impl true
  def handle_call(
        :get_users,
        _from,
        %__MODULE__{min_number: min_number, timestamp: prev_timestamp} = state
      ) do
    newstate = %__MODULE__{state | timestamp: DateTime.utc_now()}

    query =
      from u in RandomUsers.Users,
        where: u.points > ^min_number,
        limit: 2

    users = RandomUsers.Repo.all(query)

    reply = %{
      users: users,
      timestamp: prev_timestamp
    }

    {:reply, reply, newstate}
  end

  @impl true
  def handle_info(:update, %__MODULE__{} = state) do
    Process.send_after(self(), :update, 60 * 1000)
    update_users_in_batches(5_000)
    {:noreply, %__MODULE__{state | min_number: Enum.random(0..100)}}
  end

  # ok so why in batches, well, we _could_ of course just do a single update statement without any "where", but
  # doing that is, well _slow_ and annoying to the database, since it has to scan and update the entire table in one go,
  # while _techincally_ this does exactly the same thing, from the point of view of the database these are now a bunch of relatively
  # small queries, that it can execute quickly without stoppping the world so much. We still do it in a transaction, for the sake of
  # correctness, (so that any read queries would either see the new or the old state of the world), but should that not be a hard
  # requirement (and have 100x more data, or tables that are not this toy-sized), we could trivially adapt this code to do the updates
  # in a rolling fashion with jittered sleeps after each batch to keep the load on the DB primary more evenly distributed 

  defp update_users_in_batches(batch_size) do
    [min_id, max_id] =
      from(u in RandomUsers.Users, select: [min(u.id), max(u.id)]) |> RandomUsers.Repo.one()

    batches = floor((max_id - min_id) / batch_size)

    RandomUsers.Repo.transaction(fn repo ->
      now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      0..batches
      |> Enum.map(fn i ->
        {i * batch_size + min_id, Enum.min([max_id, (i + 1) * batch_size + min_id - 1])}
      end)
      |> Task.async_stream(
        fn {min, max} ->
          from(u in RandomUsers.Users,
            where: u.id >= ^min and u.id <= ^max,
            update: [set: [points: fragment("floor(random() * 101)"), updated_at: ^now]]
          )
          |> repo.update_all([])
        end,
        ordered: false
      )
      |> Stream.run()
    end)
  end
end
