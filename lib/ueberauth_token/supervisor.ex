defmodule UeberauthToken.Supervisor do
  @moduledoc false
  use Supervisor
  alias UeberauthToken.Config

  def start_link(args \\ []) do
    Confex.resolve_env!(:ueberauth_token)
    check_for_duplicate_cache_names!()
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    provider_configs =
      Enum.map(Config.providers(), fn provider ->
        %{
          provider: provider,
          use_cache: Config.use_cache?(provider),
          background_checks: Config.background_checks?(provider)
        }
      end)

    children =
      cond do
        Enum.any?(provider_configs, &match?(&1, %{use_cache: true, background_checks: true})) ->
          # Include the checking task supervisor

          task_supervisors = [
            supervisor(Task.Supervisor, [[name: UeberauthToken.CheckSupervisor]])
          ]

          # Include a cache worker for all providers with an activated cache

          cache_workers =
            provider_configs
            |> Enum.filter(& &1.use_cache)
            |> Enum.map(& &1.provider)
            |> Enum.map(&worker(Cachex, [Config.cache_name(&1), []]))

          # Include a background worker checker for all providers with `bakground_checks: true`

          background_workers =
            provider_configs
            |> Enum.filter(& &1.background_checks)
            |> Enum.map(& &1.provider)
            |> Enum.map(&worker(UeberauthToken.Worker, [[provider: &1]]))

          # Return all specs

          task_supervisors ++ cache_workers ++ background_workers

        Enum.any?(provider_configs, &match?(&1, %{use_cache: true, background_checks: false})) ->
          # Include a cache worker for all providers with an activated cache

          provider_configs
          |> Enum.filter(& &1.use_cache)
          |> Enum.map(& &1.provider)
          |> Enum.map(&worker(Cachex, [Config.cache_name(&1), []]))

        true ->
          []
      end

    supervise(children, strategy: :one_for_one, max_restarts: 5, max_seconds: 10)
  end

  defp check_for_duplicate_cache_names! do
    cache_names = Enum.map(Config.providers(), &Config.cache_name/1)

    deduplicated_cache_names =
      cache_names
      |> MapSet.new()
      |> MapSet.to_list()

    unless Enum.count(cache_names) == Enum.count(deduplicated_cache_names) do
      raise("Error, cache names must be unique")
    end
  end
end
