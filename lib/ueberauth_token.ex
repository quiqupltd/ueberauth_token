defmodule UeberauthToken do
  @moduledoc """
  A package for authenticating with an oauth2 token and building an ueberauth struct.

  Features:

  - Cache the ueberauth struct response using the excellent `whitfin/cachex` library.
  - Perform asynchronyous validity checks for each token key in the cache.

  See full description of the config options can be found in `UeberauthToken.Config` @moduledoc.

  ## Defining an provider module

  An provider module must be provided in order for UeberauthToken to function correctly. The provider
  implements the callbacks specified in the module `UeberauthToken.Strategy`. Read more about the
  requirements for the provider in `UeberauthToken.Strategy`.

  Read more on basic usage in the `UeberauthToken.Strategy` module.
  """
  alias Ueberauth.{Auth, Failure, Strategy}
  alias Ueberauth.Failure.Error
  alias UeberauthToken.Config
  alias Plug.Conn

  @token_strategy UeberauthToken.Strategy

  @doc """
  Execute token validation for an oauth2 bearer token against a
  given oauthorization server (provider).

  This function may be useful when a token needs to be validated by a resource server
  and the validation is taking place outside a `Plug` pipeline. For example, in
  a web socket connection.

  ## Options

      * `:validate_provider` - boolean
      Defaults to `true`. Validates that the provider has already been configured
      in the application configuration. It is recommended to set this
      value to `[validate_provider: false]` once it is known that the application
      is correctly configured to reduce the runtime burden of checking the
      configuration on each token validation event.

  ## Example usage

      @provider UeberauthToken.TestProvider

      def connect(%{"Authorization" => token} = params, socket) do

        case UeberauthToken.token_auth(token, @provider) do
          {:ok, %Ueberauth.Auth{} = auth} ->
            {:ok, assign(socket, :user_id, auth.uid)}

          {:error, %Ueberauth.Failure{} = failure} ->
            {:error, failure}
        end
      end
  """
  @spec token_auth(token :: String.t(), provider :: module(), opts :: list()) ::
          {:ok, Auth.t()} | {:error, Failure.t()}
  def token_auth(token, provider, opts \\ [validate_provider: true])

  def token_auth(<<"Bearer ", token::binary>>, provider, opts)
      when is_atom(provider) do
    with true <- Keyword.get(opts, :validate_provider),
         {:ok, :valid} <- Config.validate_provider(provider) do
      validate_token(token, provider)
    else
      false ->
        validate_token(token, provider)

      {:error, :invalid} ->
        invalid_provider_error(provider)
    end
  end

  def token_auth("", provider, _opts) when is_atom(provider) do
    empty_token_error(provider)
  end

  def token_auth(nil, provider, _opts) when is_atom(provider) do
    empty_token_error(provider)
  end

  def token_auth(token, provider, opts) when is_binary(token) and is_atom(provider) do
    token_auth("Bearer #{token}", provider, opts)
  end

  # private

  defp parse_ueberauth_struct(%Conn{assigns: %{ueberauth_failure: %Failure{} = auth}}) do
    {:error, auth}
  end

  defp parse_ueberauth_struct(%Conn{assigns: %{ueberauth_auth: %Auth{} = auth}}) do
    {:ok, auth}
  end

  defp invalid_provider_error(provider) do
    {:error,
     %Failure{
       errors: [
         %Error{
           message: "Invalid provider - #{provider}, ensure the provider ins configured",
           message_key: "error"
         }
       ],
       provider: provider,
       strategy: @token_strategy
     }}
  end

  defp empty_token_error(provider) do
    {:error,
     %Failure{
       errors: [
         %Error{
           message: "Empty string or null found for token",
           message_key: "error"
         }
       ],
       provider: provider,
       strategy: @token_strategy
     }}
  end

  defp validate_token(token, provider) do
    private_fields = %{
      provider: provider,
      token: %{"authorization" => "Bearer #{token}"}
    }

    try do
      %Conn{}
      |> Conn.put_private(:ueberauth_token, private_fields)
      |> Strategy.run_callback(@token_strategy)
      # ^ leads to invocation of `@token_strategy.handle_callback!/1` and `@token_strategy.auth/1`
      |> parse_ueberauth_struct()
    rescue
      e ->
        {:error,
         %Failure{
           errors: [
             %Error{
               message: "Failed attempt to verify token due to error: #{inspect(e)}",
               message_key: "error"
             }
           ],
           provider: provider,
           strategy: @token_strategy
         }}
    end
  end
end
