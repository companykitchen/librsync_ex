defmodule LibrsyncEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :librsync_ex,
      version: "0.2.0",
      elixir: "~> 1.4",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      compilers: [:elixir_make | Mix.compilers()],
      make_clean: ["clean", "distclean"],
      dialyzer_warnings: [:unmatched_returns, :error_handling, :race_conditions, :unknown],
      dialyzer_ignored_warnings: [
        {:warn_contract_supertype, :_, {:extra_range, [:_, :__protocol__, 1, :_, :_]}}
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:elixir_make, "~> 0.4", runtime: false},
      {:dialyzex, "~> 1.1", only: [:dev, :test]}
    ]
  end
end
