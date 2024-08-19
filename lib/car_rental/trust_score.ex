defmodule CarRental.TrustScore do
  @moduledoc """
  A module to calculate the trust score of clients.
  """

  alias CarRental.TrustScore.Response
  alias CarRental.TrustScore.Params

  @doc """
  Calculate the trust score of a list of clients.

  Cannot take more than 100 clients at the same time.
  """
  alias CarRental.TrustScore.RateLimiter

  @clients_limit 100

  @spec calculate_score(Params.t()) :: [Response.t()]
  def calculate_score(params) do
    with :ok <- clients_limit_not_exceeded?(params),
         :ok <- RateLimiter.increment() do
      # Simulate a delay
      :timer.sleep(4000)

      params.clients
      |> Enum.map(fn client ->
        %Response{id: client.client_id, score: :rand.uniform(100)}
      end)
    end
  end

  defp clients_limit_not_exceeded?(%{clients: clients}) when length(clients) <= @clients_limit,
    do: :ok

  defp clients_limit_not_exceeded?(_),
    do:
      {:error,
       "Cannot calculate trust score for more than #{@clients_limit} clients at the same time"}
end
