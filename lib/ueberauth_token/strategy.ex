defmodule UeberauthToken.Strategy do
  @moduledoc """
  A workflow for validation of oauth2 tokens on the resource server.

  The strategy `handle_callback/1` function is invoked for
  validation token calidation in either of the following cases:

  1. As a plug in a plug pipeline which assigns an ueberauth struct to `%Conn{}`

      pipeline :api do
        plug :accepts, ["json"]
        plug UeberauthToken.Plug, provider: UeberauthToken.TestProvider
      end

  As a plug, the callback phase of ueberauth is adapted to validate the oauth2 access token.
  The ueberauth struct is returned in the assigns fields of the struct in one of the two
  following ways:

      # Failed validation
      Plug.Conn{assigns: %{ueberauth_failure: %Ueberauth.Failure{}}}

      # Successful validation
      Plug.Conn{assigns: %{ueberauth_auth: %Ueberauth.Auth{}}}

  2. As a `token_auth/3` function call which returns an ueberauth struct.

      token_auth(token, provider, [])

  The `token_auth/3` validation function returns one of the following forms:

      # Failed validation
      %Ueberauth.Failure{}

      # Successful validation
      %Ueberauth.Auth{}

  See full description of the config options in `UeberauthToken.Config` @moduledoc.

  ## Defining an provider module

  An provider module must be specified in order for UeberauthToken to know what
  authorization server provider to validate against. The provider must
  implement the callbacks specified in the module `UeberauthToken.Strategy`.

  The following functions should be implemented by the provider module:

      @callback get_payload(token :: String.t(), opts :: list()) :: {:ok, map()} | {:error, map()}
      @callback valid_token?(token :: String.t(), opts :: list) :: boolean()
      @callback get_uid(conn :: Conn.t()) :: any()
      @callback get_credentials(conn :: Conn.t()) :: Credentials.t()
      @callback get_info(conn :: Conn.t()) :: Info.t()
      @callback get_extra(conn :: Conn.t()) :: Extra.t()
      @callback get_ttl(conn :: Conn.t()) :: integer()

  For a basic example of token validation in a plug pipeline, see `UeberauthToken.Plug`

  For a basic example of token validation as a function, see `UeberauthToken.token_auth/3`
  """
  alias Ueberauth.Strategy.Helpers
  alias Ueberauth.Auth
  alias UeberauthToken.Config
  alias Plug.Conn.TokenParsingError
  alias Plug.Conn

  @behaviour Ueberauth.Strategy
  @ttl_offset 1_000

  @doc false
  def handle_request!(%Conn{} = conn), do: conn

  @doc """
  Handles the callback as follows:

  1. Extracts token from "Bearer token" if it is in that format

  2. Tries to get the token data from the cache if
  - The cache is turned on
  - The token is present in the cache already
  - If this stage successfully retrieves the token, then subsequent steps will be skipped.

  3. By way of a callback function, it seeks data for populating the
  ueberauth struct using the token. The callback function must be provided
  through an provider in the config or can be provided manually in the
  `conn.assigns` field.

  4. The provider will cache the data if the `use_cache` configuration
  option is set to true.
  """
  @spec handle_callback!(Conn.t()) :: Conn.t()
  def handle_callback!(
        %Conn{
          private: %{
            ueberauth_token: %{
              provider: provider,
              token: %{"authorization" => raw_token}
            }
          }
        } = conn
      ) do
    case raw_token do
      nil ->
        error = Helpers.error("token", "#{validation_error_msg(provider)}. Bearer token empty")
        rework_error_struct(Helpers.set_errors!(conn, [error]), provider)

      raw_token ->
        do_handle_callback(conn, raw_token)
    end
  end

  def handle_callback!(
        %Conn{
          req_headers: req_headers,
          private: %{
            ueberauth_token: %{
              provider: provider
            }
          }
        } = conn
      ) do
    req_headers = Enum.into(req_headers, %{})

    case Map.has_key?(req_headers, "authorization") do
      true ->
        do_handle_callback(conn, req_headers["authorization"])

      false ->
        error =
          Helpers.error(
            "token",
            "#{validation_error_msg(provider)}. The authorization request header is missing"
          )

        rework_error_struct(Helpers.set_errors!(conn, [error]), provider)
    end
  end

  defp do_handle_callback(conn, bearer_token) when is_binary(bearer_token) do
    access_token = extract_token(bearer_token)

    conn =
      with %Conn{
             private: %{
               ueberauth_token: %{
                 payload: _payload
               }
             }
           } = conn <- try_use_potentially_cached_data(conn, access_token) do
        conn
      else
        %Conn{} = conn ->
          get_payload_and_return_conn(conn, access_token)

        {:error, error} ->
          error = Helpers.error(error.key, error.message)
          rework_error_struct(Helpers.set_errors!(conn, [error]), provider(conn))
      end

    conn
  end

  @doc """
  Clean up private fields after construction of the Ueberauth struct
  """
  def handle_cleanup!(%Conn{private: %{ueberauth_token: _}} = conn) do
    %{conn | private: Map.delete(conn.private, :ueberauth_token)}
    |> handle_cleanup!()
  end

  def handle_cleanup!(%Conn{} = conn) do
    conn
  end

  @doc false
  def uid(%Conn{} = conn), do: provider(conn).get_uid(conn)

  @doc false
  def credentials(%Conn{} = conn), do: provider(conn).get_credentials(conn)

  @doc false
  def info(%Conn{} = conn), do: provider(conn).get_info(conn)

  @doc false
  def extra(%Conn{} = conn), do: provider(conn).get_extra(conn)

  @doc false
  def auth(%Conn{} = conn) do
    Kernel.struct(
      Auth,
      provider: provider(conn),
      strategy: __MODULE__,
      uid: uid(conn),
      info: info(conn),
      extra: extra(conn),
      credentials: credentials(conn)
    )
  end

  @doc false
  def valid_token?(token, provider, opts \\ []) when is_binary(token) and is_atom(provider) do
    provider.valid_token?(token, opts)
  end

  # private

  def extract_token(access_token) when is_binary(access_token) do
    try do
      ["", test] = String.split(access_token, "Bearer ")
      test
    rescue
      exception ->
        reraise(
          %TokenParsingError{
            access_token: access_token,
            original_exception: exception
          },
          System.stacktrace()
        )
    end
  end

  defp get_payload_and_return_conn(%Conn{assigns: %{ueberauth_failure: _}} = conn, _) do
    conn
  end

  defp get_payload_and_return_conn(
         %Conn{
           private: %{
             ueberauth_token: ueberauth_token
           }
         } = conn,
         access_token
       ) do
    case provider(conn).get_payload(access_token) do
      {:ok, payload} ->
        maybe_put_cached_data(conn, access_token, payload)
        Conn.put_private(conn, :ueberauth_token, Map.put(ueberauth_token, :payload, payload))

      {:error, error} ->
        error = Helpers.error(error.key, error.message)
        rework_error_struct(Helpers.set_errors!(conn, [error]), provider(conn))
    end
  end

  defp maybe_put_cached_data(conn, access_token, payload) do
    with true <- Config.use_cache?(provider(conn)),
         {:ok, nil} <- Cachex.get(Config.cache_name(provider(conn)), access_token) do
      Cachex.put(
        Config.cache_name(provider(conn)),
        access_token,
        payload,
        ttl: provider(conn).get_ttl(payload) - @ttl_offset
      )
    else
      # Not using cache at all.
      false ->
        :ok

      # Token already cached, do not interfere with existing ttl
      {:ok, _payload} ->
        :ok
    end
  end

  defp try_use_potentially_cached_data(
         %Conn{
           private: %{
             ueberauth_token: ueberauth_token
           }
         } = conn,
         access_token
       ) do
    with true <- Config.use_cache?(provider(conn)),
         {:ok, nil} <- Cachex.get(Config.cache_name(provider(conn)), access_token) do
      conn
    else
      {:ok, payload} ->
        Conn.put_private(conn, :ueberauth_token, Map.put(ueberauth_token, :payload, payload))

      false ->
        conn

      _ ->
        conn
    end
  end

  defp provider(%Conn{private: %{ueberauth_token: %{provider: provider}}}) do
    provider
  end

  defp provider(%Conn{}) do
    raise("No provider found, a provider module must be specified")
  end

  defp put_strategy(%Conn{assigns: %{ueberauth_failure: failure}} = conn) do
    Conn.assign(conn, :ueberauth_failure, Map.put(failure, :strategy, __MODULE__))
  end

  defp put_provider(%Conn{assigns: %{ueberauth_failure: failure}} = conn, provider) do
    Conn.assign(conn, :ueberauth_failure, Map.put(failure, :provider, provider))
  end

  def rework_error_struct(%Conn{} = conn, provider) do
    conn
    |> put_strategy()
    |> put_provider(provider)
  end

  defp validation_error_msg(provider) when is_atom(provider) do
    provider = String.replace(Macro.underscore(provider), "/", "_")

    """
    Token validation failed for a token against the #{provider} provider
    """
  end

  @doc """
  To get the payload.

  Callback function to be implemented by the provider

  The payload in turn is put into a private field `:ueberauth_token`.

  The payload is the map from which other callback functions will
  need to build the `:ueberauth` structs.
  """
  @callback get_payload(token :: String.t(), opts :: list()) ::
              {:ok, map()} | {:error, %{key: String.t(), message: String.t()}}

  @doc """
  Verifies a token.

  Callback function to be implemented by the provider.
  """
  @callback valid_token?(token :: String.t(), opts :: list) :: boolean()

  @doc """
  To populate the ueberauth uid struct from the payload in
  `:ueberauth_token` private conn field.

  Callback function to be implemented by the provider
  """
  @callback get_uid(conn :: %Conn{private: %{ueberauth_token: %{payload: map()}}}) :: any()

  @doc """
  To populate the ueberauth credentials struct from the payload in
  `:ueberauth_token` private conn field.

  Callback function to be implemented by the provider
  """
  @callback get_credentials(conn :: %Conn{private: %{ueberauth_token: %{payload: map()}}}) ::
              Credentials.t()

  @doc """
  To populate the ueberauth info struct from the payload in
  `:ueberauth_token` private conn field.

  Callback function to be implemented by the provider
  """
  @callback get_info(conn :: %Conn{private: %{ueberauth_token: %{payload: map()}}}) :: Info.t()

  @doc """
  To populate the ueberauth extra struct from the payload in
  `:ueberauth_token` private conn field.

  Callback function to be implemented by the provider
  """
  @callback get_extra(conn :: %Conn{private: %{ueberauth_token: %{payload: map()}}}) :: Extra.t()

  @doc """
  To get the ttl from the ueberauth struct. The ttl
  must be returned n milliseconds.

  Callback function to be implemented by the provider
  """
  @callback get_ttl(payload :: map()) :: integer()
end
