defmodule UeberauthToken.ConfigTestHelpers do
  @moduledoc false
  alias UeberauthToken.Config
  alias Confex.Resolver
  alias ExUnit.Callbacks
  alias Mix.Config, as: MixConfig

  @apps [:cachex, :ueberauth_token]

  def ensure_deactivated_cache do
    MixConfig.persist(ueberauth_token: [{test_provider(), test_provider_config()}])
    start_application()
  end

  def ensure_activated_cache do
    new_config = Keyword.put(test_provider_config(), :use_cache, true)
    MixConfig.persist(ueberauth_token: [{test_provider(), new_config}])
    start_application()
  end

  def ensure_activated_cache_and_background_worker do
    new_config =
      test_provider_config()
      |> Keyword.put(:use_cache, true)
      |> Keyword.put(:background_checks, true)

    MixConfig.persist(ueberauth_token: [{test_provider(), new_config}])

    start_application()
  end

  def reset_application_on_exit do
    Callbacks.on_exit(fn ->
      MixConfig.persist(ueberauth_token: [{test_provider(), test_provider_config()}])
      MixConfig.persist(ueberauth_token: [{Config, default_ueberauth_token_providers()}])
      stop_application()
    end)
  end

  def stop_application do
    for app <- @apps do
      Application.stop(app)
    end
  end

  def start_application do
    for app <- @apps do
      Application.ensure_all_started(app)
    end
  end

  def test_provider, do: default_ueberauth_token_provider()
  def test_providers_config, do: default_ueberauth_token_providers()
  def test_provider_config, do: default_ueberauth_token_provider_config()

  def default_ueberauth_token_providers do
    "config/config.exs"
    |> Path.expand()
    |> MixConfig.read!()
    |> Kernel.get_in([:ueberauth_token, Config])
    |> Resolver.resolve!()
  end

  def default_ueberauth_token_provider do
    :erlang.hd(default_ueberauth_token_providers()[:providers])
  end

  def default_ueberauth_token_provider_config do
    "config/config.exs"
    |> Path.expand()
    |> MixConfig.read!()
    |> Kernel.get_in([:ueberauth_token, default_ueberauth_token_provider()])
    |> Resolver.resolve!()
  end
end
