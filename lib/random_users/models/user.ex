defmodule RandomUsers.Users do
  @moduledoc """
  A model for the users table, contains two fields, an id, and points
  """

  use Ecto.Schema

  schema "users" do
    field :points, :integer
    timestamps()
  end
end
