defmodule UeberauthToken.WithCache.StrategyTest do
  use UeberauthToken.TestCase
  alias Plug.Test

  describe """
  When the cache is activated and
  when the token has been cached and
  when a provider has not been set in %Conn{private: %{ueberauth_token: _}}
  """ do
    setup [
      :setup_activated_cache,
      :set_mox_from_context,
      :verify_on_exit!
    ]

    @describetag :provider

    test """
         the handle_callback!/1 function raises a FunctionClauseError
         """,
         _context do
      second_conn = Test.conn(:get, "/api", nil)

      assert_raise FunctionClauseError, fn ->
        Strategy.handle_callback!(second_conn)
      end
    end
  end

  describe """
  When the cache is activated and
  when the token has been cached and
  when the request headers lack an authorization token
  """ do
    setup [
      :setup_activated_cache,
      :set_mox_from_context,
      :verify_on_exit!
    ]

    @describetag :provider

    test """
         the handle_callback!/1 function returns %Conn{assigns: assigns} with a
         struct in the form %Ueberauth.Failure{errors: errors}
         """,
         _context do
      conn_after =
        :get
        |> Test.conn("/api", nil)
        |> put_provider()
        |> Strategy.handle_callback!()

      assert Map.has_key?(conn_after.assigns, :ueberauth_failure) == true

      assert :erlang.hd(conn_after.assigns.ueberauth_failure.errors).message ==
               """
               Token validation failed for a token against the ueberauth_token_test_provider provider\n. \
               The authorization request header is missing
               """
               |> String.trim_trailing("\n")
    end
  end

  describe """
  When the cache is activated and
  when the token has been cached and
  when a private %Conn{} field has a valid authorization token
  """ do
    setup [
      :setup_activated_cache,
      :set_mox_from_context,
      :verify_on_exit!
    ]

    @describetag :provider

    test """
         the handle_callback!/1 function returns a conn with a private payload
         """,
         _context do
      second_conn =
        :get
        |> Test.conn("/api", nil)
        |> put_provider()
        |> put_private_token("Bearer #{passing_token()}")
        |> Strategy.handle_callback!()

      expected_payload = Fixtures.payload()

      assert Map.has_key?(second_conn.assigns, :ueberauth_failure) == false
      assert Map.has_key?(second_conn.private, :ueberauth_token) == true

      assert second_conn.private.ueberauth_token.payload == expected_payload
    end
  end

  describe """
  When the cache is activated and
  when the token has been cached and
  when the request headers have an authorization token
  """ do
    setup [
      :setup_activated_cache,
      :set_mox_from_context,
      :verify_on_exit!
    ]

    @describetag :provider

    test """
         the handle_callback!/1 function returns a conn with a private payload
         """,
         _context do
      second_conn =
        :get
        |> Test.conn("/api", nil)
        |> put_provider()
        |> Conn.put_req_header("authorization", "Bearer #{passing_token()}")
        |> Strategy.handle_callback!()

      expected_payload = Fixtures.payload()

      assert Map.has_key?(second_conn.assigns, :ueberauth_failure) == false
      assert Map.has_key?(second_conn.private, :ueberauth_token) == true

      assert second_conn.private.ueberauth_token.payload == expected_payload
    end
  end
end
