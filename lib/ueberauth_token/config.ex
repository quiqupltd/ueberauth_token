defmodule UeberauthToken.Config do
  @moduledoc """
  Helper functions for ueberauth_token configuration.

  Cachex may be used for the storage of tokens temporarily by setting the option
  `:use_cache` to `true`. Cached tokens increase speed of token payload lookup but
  with the tradeoff that token invalidation may be delayed. This can optionally be
  mitigated somewhat by also using the background token worker inconjunction
  with the cached token.

  ## Example configuration

      config :ueberauth_token, UeberauthToken.Config,
        providers: {:system, :list, "TEST_TOKEN_PROVIDER", [UeberauthToken.TestProvider]}

      config :ueberauth_token, UeberauthToken.TestProvider,
        use_cache: {:system, :boolean, "TEST_USE_CACHE", false},
        cache_name: {:system, :atom, "TEST_CACHE_NAME", :ueberauth_token},
        background_checks: {:system, :boolean, "TEST_BACKGROUND_CHECKS", false},
        background_frequency: {:system, :integer, "TEST_BACKGROUND_FREQUENCY", 120},
        background_worker_log_level: {:system, :integer, "TEST_BACKGROUND_WORKER_LOG_LEVEL", :warn}

  ## Configuration options

      * `:use_cache` - boolean
      Whether or not the cache should be used at all. If set to
      true, the Cachex worker will be started in the supervision tree
      and the token will be cached.

      * `:background_checks` - boolean
      Whether or not to perform background checks on the tokens in the cache.
      If set to true, the `UeberauthToken.Worker` is started in the supervision
      tree. If unset, defaults to `false`

      * `:background_frequency` - seconds as an integer
      The frequency with which each token in the cache will be checked. The
      checks are not applied all at once, but staggered out across the
      `background_frequency` value in 30 evenly graduated phasese
      to avoid a burst of requests for the token verification. Defaults to
      `300` (5 minutes).

      * `:background_worker_log_level` - `:debug`, `:info`, `:warn` or `:error`
      The log level at which the background worker will log unexpected timeout
      and terminate events. Defaults to `:warn`

      * `:cache_name` - an atom
      The ets table name for the cache

      * `:provider` - a module
      a required provider module which implements the callbacks defined in `UeberauthToken.Strategy`.
      See `UeberauthToken.Strategy`
  """

  @background_checking_by_default? false
  @use_cache_by_default? false
  @default_background_frequency 300
  @background_worker_log_level :warn
  @default_cache_name :ueberauth_token

  @doc """
  Get the list of configured providers.
  """
  @spec providers() :: Keyword.t()
  def providers do
    case Application.get_env(:ueberauth_token, __MODULE__)[:providers] do
      {:system, :list, _, _} = config ->
        Confex.Resolver.resolve!(config)

      config ->
        config
    end
  end

  @doc """
  Get the configuration for a given provider.
  """
  @spec provider_config(provider :: module()) :: Keyword.t()
  def provider_config(provider) when is_atom(provider) do
    Application.get_env(:ueberauth_token, provider)
  end

  @doc """
  Whether the cache is to be started and used or not.

  Defaults to `true` if not set
  """
  @spec use_cache?(provider :: module()) :: boolean()
  def use_cache?(provider) when is_atom(provider) do
    Keyword.get(provider_config(provider), :use_cache, @use_cache_by_default?)
  end

  @doc """
  Whether the background checks on the token will be performed or
  not.

  Defaults to `false`
  """
  @spec background_checks?(provider :: module()) :: boolean()
  def background_checks?(provider) when is_atom(provider) do
    Keyword.get(provider_config(provider), :background_checks, @background_checking_by_default?)
  end

  @doc """
  Get the name for the cache.

  Defaults to underscored provider name concatenated with `ueberauth_token`.
  """
  @spec cache_name(provider :: module()) :: atom()
  def cache_name(provider) do
    Keyword.get(provider_config(provider), :cache_name) ||
      @default_cache_name
      |> Atom.to_string()
      |> Kernel.<>("_")
      |> Kernel.<>(String.replace(Macro.underscore(provider), "/", "_"))
      |> String.to_atom()
  end

  @doc """
  The average frequency with which background checks should be performed.

  Defaults to 300 seconds.
  """
  @spec background_frequency(provider :: module()) :: boolean()
  def background_frequency(provider) when is_atom(provider) do
    Keyword.get(provider_config(provider), :background_frequency, @default_background_frequency)
  end

  @doc """
  The log level at which the background worker will log
  unexpected timeout and terminate events.

  Defaults to `:warn`
  """
  @spec background_worker_log_level(provider :: module()) :: boolean()
  def background_worker_log_level(provider) when is_atom(provider) do
    Keyword.get(
      provider_config(provider),
      :background_worker_log_level,
      @background_worker_log_level
    )
  end

  @doc """
  Validates a provider as one which has been specified in the configuration.

  Raises and error if the provider is not configured.
  """
  @spec validate_provider!(provider :: module()) :: :ok | no_return
  def validate_provider!(provider) do
    case validate_provider(provider) do
      {:ok, :valid} ->
        :ok

      {:error, :invalid} ->
        raise("Unknown provider #{provider}, a provider must be configured")
    end
  end

  @doc """
  Validates a provider as one which has been specified in the configuration
  """
  @spec validate_provider(provider :: module()) :: {:ok, :valid} | {:error, :invalid}
  def validate_provider(provider) do
    if provider in providers() do
      {:ok, :valid}
    else
      {:error, :invalid}
    end
  end
end
