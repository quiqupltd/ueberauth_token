defmodule UeberauthToken.SetupTestHelpers do
  @moduledoc false
  import UeberauthToken.ExpectationTestHelpers,
    only: [
      failing_token: 0,
      passing_token: 0,
      expect_passing_token_info: 0,
      expect_passing_user_info: 0
    ]

  import UeberauthToken, only: [token_auth: 3]
  alias UeberauthToken.ConfigTestHelpers
  alias Plug.Conn

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

  def ensure_token_is_cached(
        %{conn: %{private: %{ueberauth_token: %{provider: provider}}}} = context
      ) do
    token_auth(passing_token(), provider, validate_provider: false)
    context
  end

  def setup_valid_token(%{conn: conn} = context) do
    %{
      context
      | conn: Conn.put_req_header(conn, "authorization", "Bearer #{passing_token()}"),
        token: passing_token()
    }
  end

  def setup_empty_token(%{conn: conn} = context) do
    %{
      context
      | conn: Conn.put_req_header(conn, "authorization", ""),
        token: ""
    }
  end

  def setup_failing_token(%{conn: conn} = context) do
    %{
      context
      | conn: Conn.put_req_header(conn, "authorization", "Bearer #{failing_token()}"),
        token: failing_token()
    }
  end

  def setup_valid_private_ueberauth_token(%{conn: conn} = context) do
    %{
      context
      | conn: put_private_token(conn, "Bearer #{passing_token()}"),
        token: passing_token()
    }
  end

  def setup_empty_private_ueberauth_token(%{conn: conn} = context) do
    %{
      context
      | conn: put_private_token(conn, ""),
        token: ""
    }
  end

  def setup_failing_private_ueberauth_token(%{conn: conn} = context) do
    %{
      context
      | conn: put_private_token(conn, "Bearer #{failing_token()}"),
        token: failing_token()
    }
  end

  def setup_provider(
        %{conn: %{private: %{ueberauth_token: ueberauth_token} = private} = conn} = context
      ) do
    provider = ConfigTestHelpers.test_provider()

    new_private = %{
      private
      | ueberauth_token: Map.put(ueberauth_token, :provider, provider)
    }

    %{
      context
      | conn: %{conn | private: new_private},
        provider: provider
    }
  end

  def setup_provider(%{conn: conn} = context) do
    provider = ConfigTestHelpers.test_provider()

    %{
      context
      | conn: put_provider(conn, provider),
        provider: provider
    }
  end

  def setup_activated_cache(context) do
    expect_passing_token_info()
    expect_passing_user_info()

    context
    |> ensure_cache_activated()
    |> setup_provider()
    |> ensure_token_is_cached()
  end

  def put_provider(%Conn{private: %{ueberauth_token: ueberauth_token}} = conn) do
    provider = ConfigTestHelpers.test_provider()
    Conn.put_private(conn, :ueberauth_token, Map.put(ueberauth_token, :provider, provider))
  end

  def put_provider(%Conn{} = conn) do
    provider = ConfigTestHelpers.test_provider()
    Conn.put_private(conn, :ueberauth_token, %{provider: provider})
  end

  def put_provider(%Conn{private: %{ueberauth_token: ueberauth_token}} = conn, provider) do
    Conn.put_private(conn, :ueberauth_token, Map.put(ueberauth_token, :provider, provider))
  end

  def put_provider(%Conn{} = conn, provider) do
    Conn.put_private(conn, :ueberauth_token, %{provider: provider})
  end

  def put_private_token(%Conn{private: %{ueberauth_token: ueberauth_token}} = conn, token) do
    Conn.put_private(
      conn,
      :ueberauth_token,
      Map.put(ueberauth_token, :token, %{"authorization" => "#{token}"})
    )
  end

  def put_private_token(%Conn{} = conn, token) do
    Conn.put_private(conn, :ueberauth_token, %{token: %{"authorization" => "#{token}"}})
  end
end
