defmodule UeberauthToken.ConfigTestHelpers do
  @moduledoc false
  alias UeberauthToken.Config
  alias Confex.Resolver
  alias ExUnit.Callbacks
  alias Mix.Project
  alias Mix.Config, as: MixConfig

  def ensure_deactivated_cache do
    Application.put_env(:ueberauth_token, test_provider(), test_provider_config())
    start_application()
  end

  def ensure_activated_cache do
    new_config = Keyword.put(test_provider_config(), :use_cache, true)
    Application.put_env(:ueberauth_token, test_provider(), new_config)
    start_application()
  end

  def ensure_activated_cache_and_background_worker do
    new_config =
      test_provider_config()
      |> Keyword.put(:use_cache, true)
      |> Keyword.put(:background_checks, true)

    Application.put_env(:ueberauth_token, test_provider(), new_config)
    start_application()
  end

  def reset_application_on_exit do
    Callbacks.on_exit(fn ->
      stop_application()
      Application.put_env(:ueberauth_token, Config, test_providers_config())
      Application.put_env(:ueberauth_token, test_provider(), test_provider_config())
    end)
  end

  def stop_application do
    Application.stop(:ueberauth_token)
  end

  def start_application do
    start_dependency_applications()
    Application.ensure_started(:ueberauth_token, :temporary)
  end

  def start_dependency_applications do
    Project.config()
    |> Keyword.get(:deps)
    |> Enum.map(&Kernel.elem(&1, 0))
    |> Enum.map(&Application.ensure_all_started(&1, :temporary))
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
