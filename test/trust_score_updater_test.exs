defmodule CarRental.TrustScoreUpdaterTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias CarRental.TrustScoreUpdater

  setup do
    :meck.new(CarRental.Clients, [:passthrough])
    :meck.new(CarRental.TrustScore, [:passthrough])
    :meck.new(ExRated, [:passthrough])

    on_exit(fn ->
      :meck.unload()
    end)

    :ok
  end

  test "update_trust_scores processes clients successfully" do
    clients = [
      %{id: 1, age: 30, license_number: "ABC123", rental_history: [1, 2, 3]},
      %{id: 2, age: 25, license_number: "DEF456", rental_history: [4, 5]}
    ]
    :meck.expect(CarRental.Clients, :list_clients, fn -> {:ok, clients} end)
    :meck.expect(CarRental.TrustScore, :calculate_score, fn _ -> [%{id: 1, score: 80}, %{id: 2, score: 75}] end)
    :meck.expect(CarRental.Clients, :save_score_for_client, fn _ -> :ok end)
    :meck.expect(ExRated, :check_rate, fn _, _, _ -> {:ok, 1} end)

    log = capture_log(fn ->
      assert :ok == TrustScoreUpdater.update_trust_scores()
    end)

    assert log =~ "Trust scores update started"
    assert log =~ "Trust scores update completed successfully"
  end

  test "update_trust_scores handles client list retrieval error" do
    :meck.expect(CarRental.Clients, :list_clients, fn -> {:error, "Database error"} end)

    log = capture_log(fn ->
      assert {:error, {:client_list_retrieval_failed, "Database error"}} == TrustScoreUpdater.update_trust_scores()
    end)

    assert log =~ "Failed to retrieve client list: \"Database error\""
  end

  test "update_trust_scores handles rate limiting" do
    clients = [%{id: 1, age: 30, license_number: "ABC123", rental_history: [1, 2, 3]}]
    :meck.expect(CarRental.Clients, :list_clients, fn -> {:ok, clients} end)
    :meck.expect(CarRental.TrustScore, :calculate_score, fn _ -> [%{id: 1, score: 80}] end)
    :meck.expect(CarRental.Clients, :save_score_for_client, fn _ -> :ok end)

    {:ok, agent} = Agent.start_link(fn -> 0 end)

    :meck.expect(ExRated, :check_rate, fn _, _, _ ->
      Agent.update(agent, &(&1 + 1))
      case Agent.get(agent, & &1) do
        1 -> {:error, :rate_limited}
        _ -> {:ok, 1}
      end
    end)

    log = capture_log(fn ->
      assert :ok == TrustScoreUpdater.update_trust_scores()
    end)

    assert log =~ "Trust scores update started"
    assert log =~ "Trust scores update completed successfully"

    Agent.stop(agent)
  end
end
