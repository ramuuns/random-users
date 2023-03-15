defmodule RandomUsersWeb.IndexController do
  use RandomUsersWeb, :controller

  def index(conn, _params) do
    data = RandomUsers.MinNumber.get_users(RandomUsers.MinNumberInstance)

    json(conn, %{
      "users" =>
        data.users
        |> Enum.map(fn %{id: id, points: points} -> %{"id" => id, "points" => points} end),
      "timestamp" => data.timestamp |> format_timestamp
    })
  end

  defp format_timestamp(nil) do
    nil
  end

  defp format_timestamp(dt) do
    dt |> DateTime.to_string() |> String.slice(0, 19)
  end
end
