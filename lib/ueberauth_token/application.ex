defmodule UeberauthToken.Application do
  @moduledoc false
  use Application
  alias UeberauthToken.Supervisor

  def start(_type, _args) do
    Supervisor.start_link([])
  end
end
