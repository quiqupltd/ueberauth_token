defmodule UeberauthToken.ConfigTest do
  @moduledoc false
  use UeberauthToken.TestCase

  @provider UeberauthToken.TestProvider

  describe "For a cache deactivated (standard) application" do
    test "providers/0" do
      assert Config.providers() == [@provider]
    end

    test "provider_config/1" do
      assert Config.provider_config(@provider) == [
               use_cache: false,
               cache_name: :ueberauth_token_test_provider,
               background_checks: false,
               background_frequency: 120,
               background_worker_log_level: :warn
             ]
    end

    test "use_cache?/1" do
      assert Config.use_cache?(@provider) == false
    end

    test "background_checks?/1" do
      assert Config.background_checks?(@provider) == false
    end

    test "cache_name/1" do
      assert Config.cache_name(@provider) == :ueberauth_token_test_provider
    end

    test "background_frequency/1" do
      assert Config.background_frequency(@provider) == 120
    end

    test "background_worker_log_level/1" do
      assert Config.background_worker_log_level(@provider) == :warn
    end

    test "validate_provider!/1 for configured provider" do
      assert Config.validate_provider!(@provider) == :ok
    end

    test "validate_provider!/1 for a non-existent provider" do
      assert_raise RuntimeError, fn ->
        Config.validate_provider!(InvalidProvider)
      end
    end

    test "validate_provider/1 for configured provider" do
      assert Config.validate_provider(@provider) == {:ok, :valid}
    end

    test "validate_provider/1 for a non-existent provider" do
      assert Config.validate_provider(InvalidProvider) == {:error, :invalid}
    end
  end

  describe "For a cache activated application" do
    setup [:ensure_cache_activated]

    test "providers/0" do
      assert Config.providers() == [@provider]
    end

    test "provider_config/1" do
      assert Config.provider_config(@provider) == [
               use_cache: true,
               cache_name: :ueberauth_token_test_provider,
               background_checks: false,
               background_frequency: 120,
               background_worker_log_level: :warn
             ]
    end

    test "use_cache?/1" do
      assert Config.use_cache?(@provider) == true
    end

    test "background_checks?/1" do
      assert Config.background_checks?(@provider) == false
    end
  end

  describe "For a cache and background checks activated application" do
    setup [:ensure_cache_and_background_worker_activated]

    test "providers/0" do
      assert Config.providers() == [@provider]
    end

    test "provider_config/1" do
      config = Config.provider_config(@provider)

      assert [
               use_cache: config[:use_cache],
               cache_name: config[:cache_name],
               background_checks: config[:background_checks],
               background_frequency: config[:background_frequency],
               background_worker_log_level: config[:background_worker_log_level]
             ] == [
               use_cache: true,
               cache_name: :ueberauth_token_test_provider,
               background_checks: true,
               background_frequency: 120,
               background_worker_log_level: :warn
             ]
    end

    test "use_cache?/1" do
      assert Config.use_cache?(@provider) == true
    end

    test "background_checks?/1" do
      assert Config.background_checks?(@provider) == true
    end
  end
end
