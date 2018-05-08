defmodule UeberauthToken.PlugTest do
  use UeberauthToken.TestCase
  alias UeberauthToken.TestPlugRouter
  alias Plug.Conn.TokenParsingError

  describe "When the request headers have a valid authorization token" do
    setup [
      :ensure_cache_deactivated,
      :setup_valid_token,
      :set_mox_from_context,
      :verify_on_exit!
    ]

    @describetag :token

    test "the plug pipeline responds and is not halted", %{conn: conn} do
      expect_passing_token_info(1)
      expect_passing_user_info(1)

      conn = TestPlugRouter.call(conn, [])

      assert conn.resp_body == "responded"
    end

    test "an authenticated plug pipeline returns a cleaned private field", %{conn: conn} do
      expect_passing_token_info(1)
      expect_passing_user_info(1)

      conn = TestPlugRouter.call(conn, [])

      assert :ueberauth_token not in conn.private
    end

    test "an authenticated plug pipeline assigns an %Auth{} struct to the conn", %{conn: conn} do
      expect_passing_token_info(1)
      expect_passing_user_info(1)

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
      expect_passing_token_info(1)
      expect_passing_user_info(1)

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

    test "the plug pipeline does not respond and instead raises with TokenParsingError exception",
         %{
           conn: conn
         } do
      expected_msg = """
      Error while processing token , only a bearer token is acceptable due\nto original exception: \
      %MatchError{term: [\"\"]}\n\nExample: \"Bearer 5a236016-07f0-4689-bf74-d7b8559b21d7\"
      """

      assert_raise TokenParsingError, expected_msg, fn ->
        TestPlugRouter.call(conn, [])
      end
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
      expect_passing_user_info(1)
      expect_failing_token_info(1)

      conn = TestPlugRouter.call(conn, [])

      assert conn.resp_body == "responded"
    end

    test "an unauthenticated plug pipeline returns a cleaned private field", %{conn: conn} do
      expect_passing_user_info(1)
      expect_failing_token_info(1)

      conn = TestPlugRouter.call(conn, [])

      assert :ueberauth_token not in conn.private
    end

    test "an unauthenticated plug pipeline assigns an %Failure{} struct to the conn", %{
      conn: conn
    } do
      expect_passing_user_info(1)
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
