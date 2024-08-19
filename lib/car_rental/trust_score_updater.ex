defmodule CarRental.TrustScoreUpdater do
  require Logger

  alias CarRental.TrustScore.Params
  alias CarRental.TrustScore.Params.ClientParams
  alias CarRental.Clients.Params, as: SaveParams

  @group_size 100
  @max_api_retries 3
  @initial_backoff 1000
  @rate_limit_id "trust_score_batch_api_calls"
  @rate_limit_scale 60_000
  @rate_limit_limit 10

  def update_trust_scores do
    Logger.info("Trust scores update started")

    case CarRental.Clients.list_clients() do
      {:ok, clients} ->
        case process_clients_in_parallel(clients) do
          :ok ->
            Logger.info("Trust scores update completed successfully")
            :ok
          {:error, reason} ->
            Logger.error("Trust scores update completed with errors: #{inspect(reason)}")
            {:error, reason}
        end

      {:error, reason} ->
        Logger.error("Failed to retrieve client list: #{inspect(reason)}")
        {:error, {:client_list_retrieval_failed, reason}}
    end
  end

  defp process_clients_in_parallel(clients) do
    results = clients
    |> Stream.chunk_every(@group_size)
    |> Stream.map(&spawn_rate_limited_client_update_task/1)
    |> Enum.to_list()
    |> Task.await_many(:infinity)

    case Enum.group_by(results, &elem(&1, 0)) do
      %{error: errors} ->
        error_reasons = Enum.map(errors, fn {:error, reason} -> reason end)
        {:error, {:some_updates_failed, error_reasons}}
      _ -> :ok
    end
  end

  defp spawn_rate_limited_client_update_task(clients) do
    with :ok <- check_and_wait_rate_limit() do
      Task.async(fn -> process_client_group(clients) end)
    end
  end

  defp check_and_wait_rate_limit do
    case ExRated.check_rate(@rate_limit_id, @rate_limit_scale, @rate_limit_limit) do
      {:ok, _} -> :ok
      {:error, _} ->
        backoff = calculate_backoff()
        :timer.sleep(backoff)
        check_and_wait_rate_limit()
    end
  end

  defp process_client_group(clients) do
    with params <- create_trust_score_params(clients),
        {:ok, responses} <- fetch_trust_scores_with_retry(params) do
      save_trust_scores(responses)
      {:ok, :processed}
    end
  end

  defp create_trust_score_params(clients) do
    %Params{
      clients: Enum.map(clients, fn client ->
        %ClientParams{
          client_id: client.id,
          age: client.age,
          license_number: client.license_number,
          rentals_count: length(client.rental_history)
        }
      end)
    }
  end

  defp fetch_trust_scores_with_retry(params, retry_count \\ 0)

  defp fetch_trust_scores_with_retry(_params, retry_count) when retry_count > @max_api_retries do
    {:error, :max_retries_reached}
  end

  defp fetch_trust_scores_with_retry(params, retry_count) do
      case CarRental.TrustScore.calculate_score(params) do
        {:error, reason} ->
          handle_retry(params, retry_count, reason)
        scores ->
          Logger.info("Processed #{length(scores)} clients.")
          {:ok, scores}
      end
  end

  defp handle_retry(params, retry_count, reason) do
    backoff = calculate_backoff(retry_count)
    Logger.warning("API call failed. Retrying after #{backoff}ms. Reason: #{inspect(reason)}")
    :timer.sleep(backoff)
    fetch_trust_scores_with_retry(params, retry_count + 1)
  end

  defp save_trust_scores(responses) do
    Enum.each(responses, fn response ->
      save_params = %SaveParams{
        client_id: response.id,
        score: response.score
      }
      CarRental.Clients.save_score_for_client(save_params)
    end)
  end

  defp calculate_backoff(retry_count \\ 0) do
    @initial_backoff * :math.pow(2, retry_count)
    |> trunc()
    |> min(60_000)  # Cap at 1 minute
  end
end
