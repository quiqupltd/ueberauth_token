defmodule UeberauthToken.Plug do
  @moduledoc """
  An implementation of Ueberauth token validation in a plug pipeline

  In order for there to be successful authentication, the `Plug.Conn`
  should have a request header in the following format:

      %Plug.Conn{req_headers: [%{"authorization" => "Bearer <token>"}]}

  ## Example Usage

  Typically, `UeberauthToken.Plug` would be used as part of plug pipeline
  in an api for the validation phase of an oauth2 token. The client will
  be in possession of a token an is making a request for a resource. This
  plug validates the requests and assigns an `Ueberauth` struct to the `%Conn{}`

      pipeline :api do
        plug :accepts, ["json"]
        plug UeberauthToken.Plug, provider: UeberauthToken.TestProvider
      end

  ## Options

      - * `:provider` - a module
      The provider may be passed in as an option if more than one provider is
      configured. The plug pipeline `plug UeberauthToken.Plug` should only be
      called once in a given plug pipeline, in other words only one provider
      per plug pipeline is supported.
  """
  alias UeberauthToken.Config
  alias Ueberauth.Strategy
  alias Plug.Conn

  @behaviour Plug
  @token_strategy UeberauthToken.Strategy

  def init(opts \\ []) do
    provider =
      Keyword.get(opts, :provider) ||
        if Enum.count(Config.providers()) == 1 do
          :erlang.hd(Config.providers())
        else
          """
          When multiple providers have been configured, a specific provider must
          be provided as an option to a UeberauthToken.Plug pipline. It can be configured by
          passing the provider option, `provider: UeberauthToken.TestProvider`"
          """
          |> raise()
        end

    Config.validate_provider!(provider)

    opts
  end

  def call(conn, opts) do
    conn
    |> Conn.put_private(:ueberauth_token, %{provider: opts[:provider]})
    |> Strategy.run_callback(@token_strategy)

    # ^ leads to invocation of `@token_strategy.handle_callback!/1` and `@token_strategy.auth/1`
  end
end
