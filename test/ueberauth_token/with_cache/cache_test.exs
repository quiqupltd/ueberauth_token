defmodule UeberauthToken.WithCache.CacheTest do
  use UeberauthToken.TestCase

  describe """
  When the cache is activated and
  when the token has been cached
  """ do
    setup [
      :setup_activated_cache,
      :set_mox_from_context,
      :verify_on_exit!
    ]

    @describetag :provider

    test "the cache is active" do
      assert Config.use_cache?(test_provider()) == true
      assert Config.cache_name(test_provider()) in :ets.all() == true
    end

    test """
         the token is stored in the cache
         """,
         _context do
      passing_token() in Cachex.keys!(:ueberauth_token_test_provider)
    end

    test """
         the payload associated with the token is as expected
         """,
         _context do
      {:ok, actual_payload} = Cachex.get(:ueberauth_token_test_provider, passing_token())
      expected_payload = Fixtures.payload()

      assert actual_payload == expected_payload
    end

    test """
         the ttl associated with the token is as expected
         """,
         _context do
      {:ok, ttl} = Cachex.ttl(:ueberauth_token_test_provider, passing_token())

      assert ttl > 0 and ttl < 10_000
    end
  end

  describe """
    When the cache is activated
  """ do
    setup [
      :ensure_cache_activated,
      :setup_provider,
      :set_mox_from_context,
      :verify_on_exit!
    ]

    @describetag :provider

    test "A passing token is cached", %{provider: provider} do
      expect_passing_token_info()
      expect_passing_user_info()

      {:ok, %Auth{credentials: %Credentials{token: token}}} =
        UeberauthToken.token_auth(passing_token(), provider)

      cache_keys =
        provider
        |> Config.cache_name()
        |> Cachex.keys!()

      assert token in cache_keys
    end

    test "A failing token is not cached", %{provider: provider} do
      expect_failing_token_info()
      expect_passing_user_info()

      {:error, %Failure{}} = UeberauthToken.token_auth(failing_token(), provider)

      cache_keys =
        provider
        |> Config.cache_name()
        |> Cachex.keys!()

      assert cache_keys == []
    end
  end
end
