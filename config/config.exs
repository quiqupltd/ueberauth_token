use Mix.Config

if Mix.env() == :test || Mix.env() == :dev do
  config :ueberauth_token, UeberauthToken.Config,
    providers: {:system, :list, "TEST_TOKEN_PROVIDER", [UeberauthToken.TestProvider]}

  config :ueberauth_token, UeberauthToken.TestProvider,
    use_cache: {:system, :boolean, "TEST_USE_CACHE", false},
    cache_name: {:system, :atom, "TEST_CACHE_NAME", :ueberauth_token_test_provider},
    background_checks: {:system, :boolean, "TEST_BACKGROUND_CHECKS", false},
    background_frequency: {:system, :integer, "TEST_BACKGROUND_FREQUENCY", 120},
    background_worker_log_level: {:system, :integer, "TEST_BACKGROUND_WORKER_LOG_LEVEL", :warn}

  config :logger,
    level: :warn,
    backends: [:console],
    compile_time_purge_level: :warn,
    utc_log: false
end
