defmodule UeberauthToken.SetupTestHelpers do
  @moduledoc false
  alias UeberauthToken.{ConfigTestHelpers, TestProviderMock}
  alias Plug.Conn
  import Mox

  @passing_user_payload "test/fixtures/passing/user_payload.json"
  @passing_token_payload "test/fixtures/passing/token_payload.json"

  def ensure_cache_deactivated(context) do
    ConfigTestHelpers.ensure_deactivated_cache()
    context
  end

  def ensure_cache_activated(context) do
    ConfigTestHelpers.ensure_activated_cache()
    context
  end

  def ensure_cache_and_background_worker_activated(context) do
    ConfigTestHelpers.ensure_activated_cache_and_background_worker()
    context
  end

  def setup_request_headers(%{conn: conn} = context) do
    token = ConfigTestHelpers.generate_token()

    %{
      context
    | conn: %{conn | req_headers: %{"authorization" => "Bearer #{token}"}},
      token: token
    }
  end

  def setup_valid_private_ueberauth_token(%{conn: conn} = context) do
    token = ConfigTestHelpers.generate_token()

    %{
      context
    | conn:
      Conn.put_private(conn, :ueberauth_token, %{
        token: %{"authorization" => "Bearer #{token}"}
      }),
      token: token
    }
  end

  def setup_provider(
        %{conn: %{private: %{ueberauth_token: ueberauth_token} = private} = conn} = context
      ) do
    new_private = %{
      private
    | ueberauth_token: Map.put(ueberauth_token, :provider, ConfigTestHelpers.test_provider())
    }

    %{
      context
    | conn: Map.put(conn, :private, new_private)
    }
  end

  def setup_provider(%{conn: %{private: _} = conn} = context) do
    %{
      context
    | conn:
      Map.put(conn, :private, %{
        ueberauth_token: %{provider: ConfigTestHelpers.test_provider()}
      })
    }
  end

  def expect_passing do
    expect(TestProviderMock, :get_token_info, 2, fn _token ->
      {:ok,
        @passing_token_payload
        |> File.read!()
        |> Jason.decode!()}
    end)

    expect(TestProviderMock, :get_user_info, 2, fn _token ->
      {:ok,
        @passing_user_payload
        |> File.read!()
        |> Jason.decode!()}
    end)
  end
end
