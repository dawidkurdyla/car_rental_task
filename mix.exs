defmodule CarRental.MixProject do
  use Mix.Project

  def project do
    [
      app: :car_rental,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :ex_rated],
      mod: {CarRental.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:typed_struct, "~> 0.3.0"},
      {:faker, "~> 0.18"},
      {:quantum, "~> 3.0"},
      {:ex_rated, "~> 2.0"},
      {:meck, "~> 0.9.2", only: :test}
    ]
  end
end
