defmodule UeberauthToken.TestCase do
  @moduledoc false
  use ExUnit.CaseTemplate
  alias Plug.Test
  alias UeberauthToken.{TestProvider, ConfigTestHelpers}

  using do
    quote do
      alias Plug.Conn

      alias UeberauthToken.{
        Config,
        Fixtures,
        Strategy,
        TestProvider,
        TestProviderMock,
        ConfigTestHelpers
      }

      alias Ueberauth.{Auth, Failure}
      alias Ueberauth.Auth.Credentials
      import UeberauthToken.ConfigTestHelpers, only: [test_provider: 0]
      import UeberauthToken.ExpectationTestHelpers
      import UeberauthToken.SetupTestHelpers
      import Mox
    end
  end

  setup_all do
    {:ok, %{}}
  end

  setup do
    ConfigTestHelpers.reset_application_on_exit()
    {:ok, %{conn: Test.conn(:get, "/api", nil)}}
  end
end
