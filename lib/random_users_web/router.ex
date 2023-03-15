defmodule RandomUsersWeb.Router do
  use RandomUsersWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", RandomUsersWeb do
    pipe_through :api

    get "/", IndexController, :index
  end
end
