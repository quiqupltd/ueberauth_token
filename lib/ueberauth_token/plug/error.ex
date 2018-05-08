defmodule Plug.Conn.TokenParsingError do
  defexception access_token: nil, original_exception: nil

  @sample_token "5a236016-07f0-4689-bf74-d7b8559b21d7"

  def message(%{
        access_token: access_token,
        original_exception: exception
      }) do
    """
    Error while processing token #{access_token}, only a bearer token is acceptable due
    to original exception: #{inspect(exception)}

    Example: "Bearer #{@sample_token}"
    """
  end

  @moduledoc """
  Error raised when the request authorization token is not valid
  """
end
