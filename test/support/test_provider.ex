defmodule UeberauthToken.TestProvider do
  @moduledoc false
  alias HTTPipe.Conn
  alias Ueberauth.Auth.{Credentials, Extra, Info}
  alias __MODULE__.Payload

  @behaviour UeberauthToken.Strategy
  @default_user_payload "test/fixtures/passing/user_payload.json"
  @default_token_payload "test/fixtures/passing/token_payload.json"

  defmodule Payload do
    @moduledoc false

    defstruct(
      user_id: nil,
      provider: UeberauthToken.TestProvider,
      token: nil,
      refresh_token: nil,
      token_type: nil,
      secret: nil,
      expires_in: 0,
      scopes: [],
      other_token_info: %{},
      name: nil,
      first_name: nil,
      last_name: nil,
      username: nil,
      email: nil,
      location: nil,
      description: nil,
      avatar: nil,
      phone: nil,
      urls: %{}
    )
  end

  @type t :: %Payload{
          # will be mapped to %Auth{}
          user_id: binary() | nil,
          provider: module(),

          # will be mapped to %Credentials{}
          token: binary() | nil,
          refresh_token: binary() | nil,
          token_type: String.t() | nil,
          secret: binary() | nil,
          expires_in: integer(),
          scopes: list(String.t()),
          other_token_info: map(),

          # will be mapped to %Info{}
          name: binary() | nil,
          first_name: binary() | nil,
          last_name: binary() | nil,
          username: binary() | nil,
          email: binary() | nil,
          location: binary() | nil,
          description: binary() | nil,
          avatar: binary() | nil,
          phone: binary() | nil,
          urls: map()
        }

  @spec get_payload(token :: String.t(), opts :: list()) :: {:ok, Payload.t()} | {:error, any()}
  def get_payload(token, _opts \\ []) do
    with {:ok, user_resp} <- api().get_user_info(token),
         {:ok, token_resp} <- api().get_token_info(token) do
      Mapail.map_to_struct(Map.merge(user_resp, token_resp), Payload)
    end
  end

  @spec valid_token?(token :: String.t(), opts :: list()) :: boolean()
  def valid_token?(_token, _opts \\ []) do
    true
  end

  @spec get_uid(conn :: Conn.t()) :: any()
  def get_uid(%{private: %{ueberauth_token: %{payload: %Payload{user_id: id}}}}) do
    id
  end

  @spec get_credentials(conn :: Conn.t()) :: Credentials.t()
  def get_credentials(%{
        private: %{
          ueberauth_token: %{
            payload: %Payload{
              token: access_token,
              refresh_token: refresh_token,
              token_type: token_type,
              secret: secret,
              expires_in: expires_in,
              scopes: scopes,
              other_token_info: other_token_info
            }
          }
        }
      })
      when is_integer(expires_in) and not is_nil(access_token) and is_list(scopes) do
    expires? = is_integer(expires_in)

    expires_at_unix =
      case expires? do
        true ->
          DateTime.to_unix(DateTime.utc_now()) + expires_in

        false ->
          DateTime.to_unix(DateTime.utc_now()) - 1
      end

    %Credentials{
      token: access_token,
      refresh_token: refresh_token,
      token_type: token_type,
      secret: secret,
      expires: expires?,
      expires_at: expires_at_unix,
      scopes: scopes,
      other: other_token_info
    }
  end

  @spec get_info(conn :: Conn.t()) :: Info.t()
  def get_info(%{
        private: %{
          ueberauth_token: %{
            payload: %Payload{
              name: name,
              first_name: first_name,
              last_name: last_name,
              username: nickname,
              email: email,
              location: location,
              description: description,
              avatar: image,
              phone: phone,
              urls: urls
            }
          }
        }
      }) do
    %Info{
      name: name,
      first_name: first_name,
      last_name: last_name,
      nickname: nickname,
      email: email,
      location: location,
      description: description,
      image: image,
      phone: phone,
      urls: urls
    }
  end

  @spec get_extra(conn :: Conn.t()) :: Extra.t()
  def get_extra(%{private: %{ueberauth_token: %{payload: %Payload{} = payload}}}) do
    %Extra{
      raw_info: payload
    }
  end

  @spec get_ttl(payload :: Payload.t()) :: integer()
  def get_ttl(%Payload{expires_in: expires_in}) do
    :timer.seconds(expires_in)
  end

  @callback get_token_info(token :: String.t()) ::
              {:ok, map()} | {:error, %{key: String.t(), message: String.t()}}
  def get_token_info(_token) do
    {:ok,
     @default_token_payload
     |> File.read!()
     |> Jason.decode!()}
  end

  @callback get_user_info(token :: String.t()) ::
              {:ok, map()} | {:error, %{key: String.t(), message: String.t()}}
  def get_user_info(_token) do
    {:ok,
     @default_user_payload
     |> File.read!()
     |> Jason.decode!()}
  end

  def api, do: UeberauthToken.TestProviderMock
end
