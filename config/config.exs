import Config

config :car_rental, CarRental.Scheduler,
  jobs: [
    trust_score_update: [
      schedule: "@weekly",
      overlap: false,
      task: {CarRental.TrustScoreUpdater, :update_trust_scores, []}
    ]
  ]
