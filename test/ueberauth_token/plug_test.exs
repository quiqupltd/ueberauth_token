defmodule UeberauthToken.PlugTest do
  use UeberauthToken.TestCase
  alias UeberauthToken.TestPlugRouter

  describe "When the request headers have a valid authorization token" do
    setup [
      :ensure_cache_deactivated,
      :setup_valid_token,
      :set_mox_from_context,
      :verify_on_exit!
    ]

    @describetag :token

    test "the plug pipeline responds and is not halted", %{conn: conn} do
      expect_passing_token_info()
      expect_passing_user_info()

      conn = TestPlugRouter.call(conn, [])

      assert conn.resp_body == "responded"
    end

    test "an authenticated plug pipeline returns a cleaned private field", %{conn: conn} do
      expect_passing_token_info()
      expect_passing_user_info()

      conn = TestPlugRouter.call(conn, [])

      assert :ueberauth_token not in conn.private
    end

    test "an authenticated plug pipeline assigns an %Auth{} struct to the conn", %{conn: conn} do
      expect_passing_token_info()
      expect_passing_user_info()

      now_unix = DateTime.to_unix(DateTime.utc_now(), :second)
      conn = TestPlugRouter.call(conn, [])

      actual_ueberauth_struct = conn.assigns.ueberauth_auth
      expected_ueberauth_struct = expected_passing_ueberauth_struct(expires_at: now_unix)

      assert :ueberauth_auth in Map.keys(conn.assigns)
      assert actual_ueberauth_struct == expected_ueberauth_struct
    end

    test "an authenticated plug pipeline returned %Auth{} struct has the expected token", %{
      conn: conn,
      token: expected_token
    } do
      expect_passing_token_info()
      expect_passing_user_info()

      conn = TestPlugRouter.call(conn, [])

      actual_ueberauth_token = conn.assigns.ueberauth_auth.credentials.token

      assert actual_ueberauth_token == expected_token
    end
  end

  describe "When the request headers have a empty authorization token" do
    setup [
      :ensure_cache_deactivated,
      :setup_empty_token,
      :set_mox_from_context,
      :verify_on_exit!
    ]

    @describetag :token

    test "the plug pipeline responds and assigns an %Failure{} struct with Bearer token error",
         %{
           conn: conn
         } do
      conn = TestPlugRouter.call(conn, [])

      assert conn.resp_body == "responded"
      assert :ueberauth_failure in Map.keys(conn.assigns)

      error_message = :erlang.hd(conn.assigns.ueberauth_failure.errors).message
      assert String.contains?(error_message, "authorization request header is missing")
    end
  end

  describe "When the request headers have a failing token and a failed token response" do
    setup [
      :ensure_cache_deactivated,
      :setup_failing_token,
      :set_mox_from_context,
      :verify_on_exit!
    ]

    @describetag :token

    test "the plug pipeline responds and is not halted", %{conn: conn} do
      expect_passing_user_info()
      expect_failing_token_info(1)

      conn = TestPlugRouter.call(conn, [])

      assert conn.resp_body == "responded"
    end

    test "an unauthenticated plug pipeline returns a cleaned private field", %{conn: conn} do
      expect_passing_user_info()
      expect_failing_token_info(1)

      conn = TestPlugRouter.call(conn, [])

      assert :ueberauth_token not in conn.private
    end

    test "an unauthenticated plug pipeline assigns an %Failure{} struct to the conn", %{
      conn: conn
    } do
      expect_passing_user_info()
      expect_failing_token_info(1)

      conn = TestPlugRouter.call(conn, [])

      actual_ueberauth_struct = conn.assigns.ueberauth_failure
      expected_ueberauth_struct = expected_failing_ueberauth_struct(:token)

      refute :ueberauth_auth in Map.keys(conn.assigns)
      assert :ueberauth_failure in Map.keys(conn.assigns)
      assert actual_ueberauth_struct == expected_ueberauth_struct
    end
  end

  describe "When the request headers have a failing token and a failed user response" do
    setup [
      :ensure_cache_deactivated,
      :setup_failing_token,
      :set_mox_from_context,
      :verify_on_exit!
    ]

    @describetag :token

    test "the plug pipeline responds and is not halted", %{conn: conn} do
      expect_failing_user_info(1)

      conn = TestPlugRouter.call(conn, [])

      assert conn.resp_body == "responded"
    end

    test "an unauthenticated plug pipeline returns a cleaned private field", %{conn: conn} do
      expect_failing_user_info(1)

      conn = TestPlugRouter.call(conn, [])

      assert :ueberauth_token not in conn.private
    end

    test "an unauthenticated plug pipeline assigns an %Failure{} struct to the conn", %{
      conn: conn
    } do
      expect_failing_user_info(1)

      conn = TestPlugRouter.call(conn, [])

      actual_ueberauth_struct = conn.assigns.ueberauth_failure
      expected_ueberauth_struct = expected_failing_ueberauth_struct(:user)

      refute :ueberauth_auth in Map.keys(conn.assigns)
      assert :ueberauth_failure in Map.keys(conn.assigns)
      assert actual_ueberauth_struct == expected_ueberauth_struct
    end
  end
end
