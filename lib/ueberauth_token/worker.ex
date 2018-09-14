defmodule UeberauthToken.Worker do
  @moduledoc """
  UeberauthToken.Worker is a background worker which verifies the authenticity of the
  cached active tokens.

  Tokens will be removed after their expiry time when the `:ttl` option is set by the `Cachex.put`
  function. However, if one wants to be more aggressive in checking the cached token
  validity then this module can be optionally activated.

  See full description of the config options in `UeberauthToken.Config` @moduledoc.
  """
  use GenServer
  require Logger
  alias UeberauthToken.{CheckSupervisor, Config, Strategy}

  @stagger_phases 30

  # public

  @spec start_link(keyword()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(opts \\ []) do
    provider = Keyword.fetch!(opts, :provider)

    GenServer.start_link(__MODULE__, opts, name: worker_name(provider))
  end

  # callbacks

  @spec init(nil | keyword() | map()) :: {:ok, {nil, %{provider: any()}}}
  def init(opts) do
    periodic_checking(opts[:provider])
    {:ok, {nil, %{provider: opts[:provider]}}}
  end

  @spec periodic_checking(atom() | binary()) :: :ok
  def periodic_checking(provider) do
    GenServer.cast(worker_name(provider), :periodic_checking)
  end

  # genserver callbacks

  def handle_cast(:periodic_checking, {_timer, %{provider: provider} = state}) do
    do_checks(provider)

    timer =
      __MODULE__
      |> Process.whereis()
      |> Process.send_after(:periodic_checking, check_frequency(provider))

    {:noreply, {timer, state}, max_checking_time(provider)}
  end

  # handles the loop messaging from Process.send_after/3
  def handle_info(:periodic_checking, {timer, %{provider: provider} = state}) do
    timer && Process.cancel_timer(timer)
    periodic_checking(provider)
    {:noreply, {timer, state}}
  end

  # Handles the messages potentially returned from Task.async_nolink
  def handle_info({_ref, {:ok, :token_removed}}, {timer, state}) do
    {:noreply, {timer, state}}
  end

  # Handles the messages potentially returned from Task.async_nolink
  def handle_info({_ref, {:ok, :token_intact}}, {timer, state}) do
    {:noreply, {timer, state}}
  end

  # Handles the messages potentially returned from Task.async_nolink
  def handle_info({:DOWN, _ref, :process, _pid, :normal}, {timer, state}) do
    {:noreply, {timer, state}}
  end

  def handle_info(:timeout, {timer, %{provider: provider} = state}) do
    msg = """
    #{worker_details(provider)} timed out, #{inspect({timer, state})},
    #{location(__ENV__)}
    """

    :erlang.apply(Logger, Config.background_worker_log_level(provider), [msg])

    {:noreply, {timer, state}}
  end

  def terminate(_reason, {timer, %{provider: provider} = state}) do
    msg = """
    #{worker_details(provider)} terminated, #{inspect({timer, state})},
    #{location(__ENV__)}
    """

    :erlang.apply(Logger, Config.background_worker_log_level(provider), [msg])

    :ok
  end

  # private

  defp check_frequency(provider) do
    provider
    |> Config.background_frequency()
    |> :timer.seconds()
  end

  defp max_checking_time(provider) do
    check_frequency(provider) + 1000
  end

  # returns the amount of time to stagger the task token checking chunks by in milliseconds
  defp batch_stagger_time(provider) do
    provider
    |> max_checking_time()
    |> Kernel./(@stagger_phases)
    |> Kernel.round()
  end

  defp token_stagger_time(interval, number_of_tokens) do
    interval
    |> Kernel./(number_of_tokens)
    |> Kernel.round()
  end

  defp do_checks(provider) do
    provider
    |> Config.cache_name()
    |> Cachex.keys()
    |> do_checks_with_keys(provider)
  end

  defp do_checks_with_keys({:error, :no_cache}, _provider), do: nil

  defp do_checks_with_keys({:ok, tokens}, provider) do
    steps =
      tokens
      |> Enum.count()
      |> Kernel./(@stagger_phases)
      |> Kernel.round()

    steps = (steps > 0 && steps) || 1

    # Stagger http requests in staggered in time by
    #  1. batches of tokens and further staggered in time by
    #  2. individual tokens
    tokens
    |> Enum.chunk(steps, steps, [])
    |> Enum.with_index(1)
    |> Enum.each(fn {token_batch, index} ->
      stagger_by = batch_stagger_time(provider) * index
      validate_batch_of_tokens(token_batch, provider)
      :timer.sleep(stagger_by)
    end)
  end

  defp validate_batch_of_tokens(token_batch, provider) do
    token_stagger_by =
      provider
      |> batch_stagger_time()
      |> token_stagger_time(Enum.count(token_batch))

    for token <- token_batch do
      # Fire and forget
      Task.Supervisor.async_nolink(
        CheckSupervisor,
        fn ->
          remove_token_if_invalid(token, provider)
        end,
        timeout: batch_stagger_time(provider) + 1000
      )

      :timer.sleep(token_stagger_by)
    end
  end

  defp valid_token?(token, provider) when is_binary(token) do
    Strategy.valid_token?(token, provider)
  end

  defp remove_token_if_invalid(token, provider) do
    with false <- valid_token?(token, provider),
         {:ok, true} <- remove_token(token, provider) do
      {:ok, :token_removed}
    else
      true ->
        {:ok, :token_intact}
    end
  end

  defp remove_token(token, provider) when is_binary(token) do
    Cachex.del(Config.cache_name(provider), token)
  end

  defp location(%Macro.Env{} = env) do
    """
    module: #{inspect(env.module)},
    function: #{inspect(env.function)},
    line: #{inspect(env.line)}
    """
  end

  @spec worker_details(atom() | binary()) :: <<_::64, _::_*8>>
  def worker_details(provider) do
    "worker #{worker_name(provider)} with process_id #{
      inspect(Process.whereis(worker_name(provider)))
    }"
  end

  defp worker_name(provider) do
    __MODULE__
    |> Macro.underscore()
    |> String.replace("/", "_")
    |> Kernel.<>("_")
    |> Kernel.<>(String.replace(Macro.underscore(provider), "/", "_"))
    |> String.to_atom()
  end
end
