defmodule UeberauthToken.ExpectationTestHelpers do
  @moduledoc false
  alias UeberauthToken.{Fixtures, TestProviderMock}
  import Mox

  @passing_user_payload "test/fixtures/passing/user_payload.json"
  @passing_token_payload "test/fixtures/passing/token_payload.json"
  @failing_user_payload "test/fixtures/failing/user_payload.json"
  @failing_token_payload "test/fixtures/failing/token_payload.json"
  @passing_auth_module_path "test/fixtures/ueberauth.exs"
  @passing_token_string "5a236016-07f0-4689-bf74-d7b8559b21d7"
  @failing_token_string "5a236016-07f0-4689-bf74-d7b8559b21d8"
  @expires_in 10

  @passing_auth_module_path
  |> Path.expand()
  |> Code.require_file()

  Code.ensure_compiled(UeberauthToken.Fixtures)

  def expect_passing_user_info(number_of_invocations \\ 1) do
    expect(TestProviderMock, :get_user_info, number_of_invocations, fn _token ->
      {:ok,
       @passing_user_payload
       |> File.read!()
       |> Jason.decode!()}
    end)
  end

  def expect_passing_token_info(number_of_invocations \\ 1) do
    expect(TestProviderMock, :get_token_info, number_of_invocations, fn _token ->
      {:ok,
       @passing_token_payload
       |> File.read!()
       |> Jason.decode!()}
    end)
  end

  def expect_failing_user_info(number_of_invocations \\ 1) do
    expect(TestProviderMock, :get_user_info, number_of_invocations, fn _token ->
      {:error,
       @failing_user_payload
       |> File.read!()
       |> Jason.decode!(keys: :atoms)}
    end)
  end

  def expect_failing_token_info(number_of_invocations \\ 1) do
    expect(TestProviderMock, :get_token_info, number_of_invocations, fn _token ->
      {:error,
       @failing_token_payload
       |> File.read!()
       |> Jason.decode!(keys: :atoms)}
    end)
  end

  def expected_passing_ueberauth_struct(opts) do
    opts
    |> Keyword.fetch!(:expires_at)
    |> Kernel.+(@expires_in)
    |> Fixtures.passing()
  end

  def expected_failing_ueberauth_struct(:token) do
    Fixtures.failing(:token)
  end

  def expected_failing_ueberauth_struct(:user) do
    Fixtures.failing(:user)
  end

  def expected_failing_ueberauth_struct(:empty_token) do
    Fixtures.failing(:empty_token)
  end

  def expected_failing_ueberauth_struct(:invalid_provider, :validate_provider) do
    Fixtures.failing(:invalid_provider, :validate_provider)
  end

  def expected_failing_ueberauth_struct(:invalid_provider, :do_not_validate_provider) do
    Fixtures.failing(:invalid_provider, :do_not_validate_provider)
  end

  def passing_token, do: @passing_token_string
  def failing_token, do: @failing_token_string
end
