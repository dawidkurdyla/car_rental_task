defmodule CarRental.TrustScore.RateLimiter do
  @moduledoc """
  Naive rate limiter to limit the number of requests to the trust score service.

  The rate limiter allows a maximum of 5 requests per minute.
  """

  use GenServer

  @requests_per_minute 10

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{requests: 0, last_request_minute: nil}}
  end

  def handle_call(:increment, _from, state) do
    current_minute = div(:os.system_time(:second), 60)

    cond do
      current_minute != state.last_request_minute ->
        {:reply, :ok, %{state | requests: 1, last_request_minute: current_minute}}

      current_minute == state.last_request_minute && state.requests >= @requests_per_minute ->
        {:reply, {:error, "Rate limit exceeded"},
         %{state | requests: state.requests, last_request_minute: current_minute}}

      true ->
        {:reply, :ok,
         %{state | requests: state.requests + 1, last_request_minute: current_minute}}
    end
  end

  @doc """
  Increment the rate limiter.

  Returns `:ok` if the request is allowed, or `{:error, "Rate limit exceeded"}`
  if the request is not allowed.
  """
  @spec increment :: :ok | {:error, String.t()}
  def increment do
    GenServer.call(__MODULE__, :increment)
  end
end
