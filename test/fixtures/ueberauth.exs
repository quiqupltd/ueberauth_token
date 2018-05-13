defmodule UeberauthToken.Fixtures do
  @moduledoc false

  def passing(expires_at) do
    %Ueberauth.Auth{
      credentials: %Ueberauth.Auth.Credentials{
        expires: true,
        expires_at: expires_at,
        other: %{},
        refresh_token: nil,
        scopes: ["read", "write"],
        secret: nil,
        token: "5a236016-07f0-4689-bf74-d7b8559b21d7",
        token_type: "Bearer"
      },
      extra: %Ueberauth.Auth.Extra{
        raw_info: %UeberauthToken.TestProvider.Payload{
          avatar: nil,
          description: nil,
          email: "johndoe@quiqup.com",
          expires_in: 10,
          first_name: "John",
          last_name: "Doe",
          location: "London",
          name: "John Doe",
          other_token_info: %{},
          phone: nil,
          provider: UeberauthToken.TestProvider,
          refresh_token: nil,
          scopes: ["read", "write"],
          secret: nil,
          token: "5a236016-07f0-4689-bf74-d7b8559b21d7",
          token_type: "Bearer",
          urls: %{
            "homepage" => "https://www.quiqup.com/"
          },
          user_id: 1,
          username: "john_d"
        }
      },
      info: %Ueberauth.Auth.Info{
        description: nil,
        email: "johndoe@quiqup.com",
        first_name: "John",
        image: nil,
        last_name: "Doe",
        location: "London",
        name: "John Doe",
        nickname: "john_d",
        phone: nil,
        urls: %{
          "homepage" => "https://www.quiqup.com/"
        }
      },
      provider: UeberauthToken.TestProvider,
      strategy: UeberauthToken.Strategy,
      uid: 1
    }
  end

  def failing(:user) do
    %Ueberauth.Failure{
      errors: [
        %Ueberauth.Failure.Error{
          message: "An invalid request for a user",
          message_key: "invalid user"
        }
      ],
      provider: UeberauthToken.TestProvider,
      strategy: UeberauthToken.Strategy
    }
  end

  def failing(:token) do
    %Ueberauth.Failure{
      errors: [
        %Ueberauth.Failure.Error{
          message: "An invalid access token has been received by the server",
          message_key: "invalid_token"
        }
      ],
      provider: UeberauthToken.TestProvider,
      strategy: UeberauthToken.Strategy
    }
  end
end
