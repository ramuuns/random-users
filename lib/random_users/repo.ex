defmodule RandomUsers.Repo do
  use Ecto.Repo,
    otp_app: :random_users,
    adapter: Ecto.Adapters.Postgres
end
