defmodule CarRental.QuantumSchedulerTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias CarRental.Scheduler

  test "TrustScoreUpdater job is scheduled" do
    jobs = Scheduler.jobs()
    assert Enum.any?(jobs, fn {_, job} ->
      job.task == {CarRental.TrustScoreUpdater, :update_trust_scores, []}
    end)
  end

  test "TrustScoreUpdater job is added" do
    :meck.new(CarRental.Clients, [:passthrough])
    :meck.expect(CarRental.Clients, :list_clients, fn -> {:ok, []} end)

    log = capture_log(fn ->
      Scheduler.run_job(:trust_score_update)
      # Give some time for the job to complete and log
      Process.sleep(100)
    end)

    assert log =~ "Trust scores update started"
    assert log =~ "Trust scores update completed"


    :meck.unload(CarRental.Clients)
  end
end
