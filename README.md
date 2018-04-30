# UeberauthToken [![Hex Version](http://img.shields.io/hexpm/v/ueberauth_token.svg?style=flat-square)](https://hex.pm/packages/ueberauth_token) [![Hex docs](http://img.shields.io/badge/hex.pm-docs-green.svg?style=flat-square)](https://hexdocs.pm/ueberauth_token) [![License](https://img.shields.io/hexpm/l/ueberauth_token.svg?style=flat-square)](https://github.com/QuiqUpLTD/ueberauth_token/blob/master/LICENSE.md) [![Build Status](https://travis-ci.org/QuiqUpLTD/ueberauth_token.svg)](https://travis-ci.org/QuiqUpLTD/ueberauth_token) [![Code coverage status](https://coveralls.io/repos/github/QuiqUpLTD/ueberauth_token/badge.svg?branch=master)](https://coveralls.io/github/QuiqUpLTD/ueberauth_token?branch=master)

## Description


UeberauthToken is a library which helps validate an oauth2 token received by the resource
server. The token should be validated against the authorization server and an ueberauth struct
constructed.

## Features


- Helper function to validate the oauth2 token in a request to a resource server
- Plug to validate the oauth2 token in a request to a resource server
- Cache the ueberauth struct response using the excellent `whitfin/cachex` library.
- Perform asynchronyous validity checks for each token key in the cache.

## Prerequisites

- Definition of a provider module which implements the following callbacks


```elixir
@callback get_payload(token :: String.t(), opts :: list()) :: {:ok, map()} | {:error, map()}
@callback valid_token?(token :: String.t(), opts :: list) :: boolean()
@callback get_uid(conn :: Conn.t()) :: any()
@callback get_credentials(conn :: Conn.t()) :: Credentials.t()
@callback get_info(conn :: Conn.t()) :: Info.t()
@callback get_extra(conn :: Conn.t()) :: Extra.t()
@callback get_ttl(conn :: Conn.t()) :: integer()
```

## Basic Usage


#### 1. By adding a plug in a plug pipeline

```elixir
pipeline :api do
  plug :accepts, ["json"]
  plug UeberauthToken.Plug, provider: UeberauthToken.TestProvider
end
```

The output from the pipeline should be in one of the two forms as follows:

```elixir
# Failed validation
Plug.Conn{assigns: %{ueberauth_failure: %Ueberauth.Failure{}}}

# Successful validation
Plug.Conn{assigns: %{ueberauth_auth: %Ueberauth.Auth{}}}
```

#### 2. By calling `UeberauthToken.token_auth/3`

```elixir
UeberauthToken.token_auth("a2b62c2a-74de-417a-9038-deaf6a98c6c0", UeberauthToken.TestProvider, [])
```

The output from the pipeline should be in one of the two forms as follows:

```elixir
# Failed validation
%Ueberauth.Failure{}

# Successful validation
%Ueberauth.Auth{}
```
## Installation


#### Add package as a dependency

The [ueberauth_token package](https://hex.pm/ueberauth_token) can be installed
by adding `ueberauth_token` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ueberauth_token, "~> 0.1.0"}
  ]
end
```

#### Define an adapter module


See `UeberauthToken.TestProvider` as an example approach to writing an adapter.

#### Add the configuration to `config/config.exs`


```elixir
config :ueberauth_token, UeberauthToken.Config,
  providers: [SomeProvider]

config :ueberauth_token, SomeProvider,
  use_cache: false,
  cache_name: :ueberauth_token_some_provider,
  background_checks: false,
  background_frequency: 600,
  background_worker_log_level: :warn
```
    
*Note:* The configuration also supports [confex](https://hex.pm/packages/confex) style configurations.

## Tests

```elixir
MIX_ENV=test mix test
```
    
## Authors


- Stephen Moloney (*[Stephen Moloney](https://github.com/stephenmoloney)*)

## License


MIT License.
See [LICENSE.md](https://github.com/QuiqUpLTD/ueberauth_token/blob/master/LICENSE.md) for further details.

[hexdocs]: https://hexdocs.pm/ueberauth_token/0.1.0/UeberauthToken.html
