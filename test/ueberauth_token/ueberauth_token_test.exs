defmodule UeberauthToken.UeberauthTokenTest do
  use UeberauthToken.TestCase

  describe """
    When executing token_auth/3 with a valid token and provider
    and opts are validating the provider
  """ do
    setup [
      :ensure_cache_deactivated,
      :setup_valid_private_ueberauth_token,
      :setup_provider,
      :set_mox_from_context,
      :verify_on_exit!
    ]

    @describetag :token
    @describetag :provider

    test "an %Auth{} struct is successfully returned", %{
      token: token,
      provider: provider
    } do
      expect_passing_token_info()
      expect_passing_user_info()

      now_unix = DateTime.to_unix(DateTime.utc_now(), :second)
      {:ok, %Auth{} = actual_ueberauth_struct} = UeberauthToken.token_auth(token, provider)

      expected_ueberauth_struct = expected_passing_ueberauth_struct(expires_at: now_unix)

      assert actual_ueberauth_struct == expected_ueberauth_struct
    end

    test "an %Auth{} struct is successfully returned with the expected token", %{
      token: token,
      provider: provider
    } do
      expect_passing_token_info()
      expect_passing_user_info()

      {:ok, %Auth{} = actual_ueberauth_struct} = UeberauthToken.token_auth(token, provider)
      actual_ueberauth_token = actual_ueberauth_struct.credentials.token

      assert actual_ueberauth_token == token
    end
  end

  describe """
    When executing token_auth/3 with a valid token and provider
    and opts are not validating the provider
  """ do
    setup [
      :ensure_cache_deactivated,
      :setup_valid_private_ueberauth_token,
      :setup_provider,
      :set_mox_from_context,
      :verify_on_exit!
    ]

    @describetag :token
    @describetag :provider

    test "an %Auth{} struct is successfully returned", %{
      token: token,
      provider: provider
    } do
      expect_passing_token_info()
      expect_passing_user_info()

      now_unix = DateTime.to_unix(DateTime.utc_now(), :second)
      opts = [validate_provider: false]
      {:ok, %Auth{} = actual_ueberauth_struct} = UeberauthToken.token_auth(token, provider, opts)

      expected_ueberauth_struct = expected_passing_ueberauth_struct(expires_at: now_unix)

      assert actual_ueberauth_struct == expected_ueberauth_struct
    end

    test "an %Auth{} struct is successfully returned with the expected token", %{
      token: token,
      provider: provider
    } do
      expect_passing_token_info()
      expect_passing_user_info()

      opts = [validate_provider: false]
      {:ok, %Auth{} = actual_ueberauth_struct} = UeberauthToken.token_auth(token, provider, opts)
      actual_ueberauth_token = actual_ueberauth_struct.credentials.token

      assert actual_ueberauth_token == token
    end
  end

  describe """
    When executing token_auth/3 with a valid token and an invalid provider
    and opts are validating the provider
  """ do
    setup [
      :ensure_cache_deactivated,
      :setup_valid_private_ueberauth_token,
      :set_mox_from_context,
      :verify_on_exit!
    ]

    @describetag :token
    @describetag :provider

    test "a %Failure{} struct is returned with details about the invalid provider", %{
      token: token
    } do
      provider = InvalidProvider
      {:error, %Failure{} = actual_ueberauth_struct} = UeberauthToken.token_auth(token, provider)

      expected_ueberauth_struct =
        expected_failing_ueberauth_struct(:invalid_provider, :validate_provider)

      assert actual_ueberauth_struct == expected_ueberauth_struct
    end
  end

  describe """
    When executing token_auth/3 with a valid token and an invalid provider
    and opts are not validating the provider
  """ do
    setup [
      :ensure_cache_deactivated,
      :setup_valid_private_ueberauth_token,
      :set_mox_from_context,
      :verify_on_exit!
    ]

    @describetag :token
    @describetag :provider

    test "a %Failure{} struct is returned with details about a trapped FunctionClauseError", %{
      token: token
    } do
      provider = InvalidProvider
      opts = [validate_provider: false]

      {:error, %Failure{} = actual_ueberauth_struct} =
        UeberauthToken.token_auth(token, provider, opts)

      expected_ueberauth_struct =
        expected_failing_ueberauth_struct(:invalid_provider, :do_not_validate_provider)

      assert actual_ueberauth_struct == expected_ueberauth_struct
    end
  end

  describe """
    When executing token_auth/3 with an empty token and valid provider
    and opts are validating the provider
  """ do
    setup [
      :ensure_cache_deactivated,
      :setup_empty_private_ueberauth_token,
      :setup_provider,
      :set_mox_from_context,
      :verify_on_exit!
    ]

    @describetag :token
    @describetag :provider

    test "a %Failure{} struct is returned", %{
      token: token,
      provider: provider
    } do
      {:error, %Failure{} = actual_ueberauth_struct} = UeberauthToken.token_auth(token, provider)

      expected_ueberauth_struct = expected_failing_ueberauth_struct(:empty_token)

      assert actual_ueberauth_struct == expected_ueberauth_struct
    end
  end

  describe """
    When executing token_auth/3 with an invalid token and a valid provider
    and opts are validating the provider and a failing token_info request
  """ do
    setup [
      :ensure_cache_deactivated,
      :setup_failing_private_ueberauth_token,
      :setup_provider,
      :set_mox_from_context,
      :verify_on_exit!
    ]

    @describetag :token
    @describetag :provider

    test "a %Failure{} struct is returned", %{
      token: token,
      provider: provider
    } do
      expect_failing_token_info(1)
      expect_passing_user_info()

      {:error, %Failure{} = actual_ueberauth_struct} = UeberauthToken.token_auth(token, provider)

      expected_ueberauth_struct = expected_failing_ueberauth_struct(:token)

      assert actual_ueberauth_struct == expected_ueberauth_struct
    end
  end

  describe """
    When executing token_auth/3 with an invalid token and a valid provider
    and opts are validating the provider and a failing token_user request
  """ do
    setup [
      :ensure_cache_deactivated,
      :setup_failing_private_ueberauth_token,
      :setup_provider,
      :set_mox_from_context,
      :verify_on_exit!
    ]

    @describetag :token
    @describetag :provider

    test "a %Failure{} struct is returned", %{
      token: token,
      provider: provider
    } do
      expect_failing_user_info(1)

      {:error, %Failure{} = actual_ueberauth_struct} = UeberauthToken.token_auth(token, provider)

      expected_ueberauth_struct = expected_failing_ueberauth_struct(:user)

      assert actual_ueberauth_struct == expected_ueberauth_struct
    end
  end
end
