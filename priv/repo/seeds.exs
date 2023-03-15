# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     RandomUsers.Repo.insert!(%RandomUsers.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# break up the population of the initial 1M of users into 1K batches of 1K to be nicer to both the computer and the database
# also no reason not to run some of that in paralel
now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

1..1000
|> Task.async_stream(fn _ ->
  RandomUsers.Repo.insert_all(
    RandomUsers.Users,
    1..1000 |> Enum.map(fn _ -> [points: 0, inserted_at: now, updated_at: now] end)
  )
end)
|> Enum.map(fn _ -> :ok end)
