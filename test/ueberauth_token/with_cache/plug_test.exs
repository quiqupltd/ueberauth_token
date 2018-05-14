defmodule UeberauthToken.WithCache.PlugTest do
  use UeberauthToken.TestCase
  alias UeberauthToken.TestPlugRouter
  alias Plug.Conn.TokenParsingError
  alias Plug.Test

  describe """
  When the cache is activated and
  when the token has been cached and
  when the request headers have a valid authorization token and
  without needing to make another request,
  """ do
    setup [
      :setup_activated_cache,
      :set_mox_from_context,
      :verify_on_exit!
    ]

    @describetag :provider

    test """
           the plug pipeline responds and is not halted
         """,
         _context do
      second_conn =
        :get
        |> Test.conn("/api", nil)
        |> Conn.put_req_header("authorization", "Bearer #{passing_token()}")
        |> TestPlugRouter.call([])

      assert second_conn.resp_body == "responded"
    end

    test """
           an authenticated plug pipeline returns a cleaned private field
         """,
         _context do
      second_conn =
        :get
        |> Test.conn("/api", nil)
        |> Conn.put_req_header("authorization", "Bearer #{passing_token()}")
        |> TestPlugRouter.call([])

      assert :ueberauth_token not in second_conn.private
    end

    test """
           an authenticated plug pipeline assigns an %Auth{} struct to the conn
         """,
         _context do
      now_unix = DateTime.to_unix(DateTime.utc_now(), :second)

      second_conn =
        :get
        |> Test.conn("/api", nil)
        |> Conn.put_req_header("authorization", "Bearer #{passing_token()}")
        |> TestPlugRouter.call([])

      actual_ueberauth_struct = second_conn.assigns.ueberauth_auth
      expected_ueberauth_struct = expected_passing_ueberauth_struct(expires_at: now_unix)

      assert :ueberauth_auth in Map.keys(second_conn.assigns)
      assert actual_ueberauth_struct == expected_ueberauth_struct
    end

    test "an authenticated plug pipeline returned %Auth{} struct has the expected token",
         _context do
      second_conn =
        :get
        |> Test.conn("/api", nil)
        |> Conn.put_req_header("authorization", "Bearer #{passing_token()}")
        |> TestPlugRouter.call([])

      actual_ueberauth_token = second_conn.assigns.ueberauth_auth.credentials.token

      assert actual_ueberauth_token == passing_token()
    end
  end

  describe """
  When the cache is activated and
  when the token has been cached and
  when the request headers have an empty authorization token and
  without needing to make another request,
  """ do
    setup [
      :setup_activated_cache,
      :set_mox_from_context,
      :verify_on_exit!
    ]

    @describetag :token
    @describetag :provider

    test "the plug pipeline raises a TokenParsingError exception", _context do
      expected_msg = """
      Error while processing token , only a bearer token is acceptable due\nto original exception: \
      %MatchError{term: [\"\"]}\n\nExample: \"Bearer 5a236016-07f0-4689-bf74-d7b8559b21d7\"
      """

      assert_raise TokenParsingError, expected_msg, fn ->
        :get
        |> Test.conn("/api", nil)
        |> Conn.put_req_header("authorization", "")
        |> TestPlugRouter.call([])
      end
    end
  end

  describe """
  When the cache is activated and
  when the token has been cached and
  when the request headers have a failing token and a failed token response
  """ do
    setup [
      :setup_activated_cache,
      :set_mox_from_context,
      :verify_on_exit!
    ]

    @describetag :token
    @describetag :provider

    test """
           the plug pipeline responds and is not halted
         """,
         _context do
      expect_passing_user_info()
      expect_failing_token_info()

      second_conn =
        :get
        |> Test.conn("/api", nil)
        |> Conn.put_req_header("authorization", "Bearer #{failing_token()}")
        |> TestPlugRouter.call([])

      assert second_conn.resp_body == "responded"
    end

    test """
           an unauthenticated plug pipeline returns a cleaned private field
         """,
         _context do
      expect_passing_user_info()
      expect_failing_token_info()

      second_conn =
        :get
        |> Test.conn("/api", nil)
        |> Conn.put_req_header("authorization", "Bearer #{failing_token()}")
        |> TestPlugRouter.call([])

      assert :ueberauth_token not in second_conn.private
    end

    test """
           an unauthenticated plug pipeline assigns an %Failure{} struct to the conn
         """,
         _context do
      expect_passing_user_info()
      expect_failing_token_info()

      second_conn =
        :get
        |> Test.conn("/api", nil)
        |> Conn.put_req_header("authorization", "Bearer #{failing_token()}")
        |> TestPlugRouter.call([])

      actual_ueberauth_struct = second_conn.assigns.ueberauth_failure
      expected_ueberauth_struct = expected_failing_ueberauth_struct(:token)

      refute :ueberauth_auth in Map.keys(second_conn.assigns)
      assert :ueberauth_failure in Map.keys(second_conn.assigns)
      assert actual_ueberauth_struct == expected_ueberauth_struct
    end
  end

  describe """
    When the cache is activated and
    when the token has been cached and
    when the request headers have a failing token and a failed user response
  """ do
    setup [
      :setup_activated_cache,
      :set_mox_from_context,
      :verify_on_exit!
    ]

    @describetag :token
    @describetag :provider

    test """
           the plug pipeline responds and is not halted
         """,
         _context do
      expect_failing_user_info()

      second_conn =
        :get
        |> Test.conn("/api", nil)
        |> Conn.put_req_header("authorization", "Bearer #{failing_token()}")
        |> TestPlugRouter.call([])

      assert second_conn.resp_body == "responded"
    end

    test """
           an unauthenticated plug pipeline returns a cleaned private field
         """,
         _context do
      expect_failing_user_info()

      second_conn =
        :get
        |> Test.conn("/api", nil)
        |> Conn.put_req_header("authorization", "Bearer #{failing_token()}")
        |> TestPlugRouter.call([])

      assert :ueberauth_token not in second_conn.private
    end

    test """
           an unauthenticated plug pipeline assigns an %Failure{} struct to the conn
         """,
         _context do
      expect_failing_user_info()

      second_conn =
        :get
        |> Test.conn("/api", nil)
        |> Conn.put_req_header("authorization", "Bearer #{failing_token()}")
        |> TestPlugRouter.call([])

      actual_ueberauth_struct = second_conn.assigns.ueberauth_failure
      expected_ueberauth_struct = expected_failing_ueberauth_struct(:user)

      refute :ueberauth_auth in Map.keys(second_conn.assigns)
      assert :ueberauth_failure in Map.keys(second_conn.assigns)
      assert actual_ueberauth_struct == expected_ueberauth_struct
    end
  end
end
