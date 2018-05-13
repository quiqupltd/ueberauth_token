defmodule UeberauthToken.TestPlugRouter do
  @moduledoc false
  use Plug.Router
  alias Plug.Conn

  plug(:match)
  plug(:dispatch)
  plug(UeberauthToken.Plug, provider: UeberauthToken.TestProvider)

  get "/api" do
    Conn.resp(conn, 200, "responded")
  end
end
