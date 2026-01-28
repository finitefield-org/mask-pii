defmodule MaskPii.MixProject do
  use Mix.Project

  def project do
    [
      app: :mask_pii,
      version: "0.2.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: [],
      description: "A lightweight library to mask PII (emails and phone numbers).",
      source_url: "https://github.com/finitefield-org/mask-pii",
      homepage_url: "https://finitefield.org/en/oss/mask-pii",
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      name: "mask_pii",
      licenses: ["MIT"],
      links: %{
        "Homepage" => "https://finitefield.org/en/oss/mask-pii",
        "Repository" => "https://github.com/finitefield-org/mask-pii",
        "Issues" => "https://github.com/finitefield-org/mask-pii/issues"
      },
      files: [
        "lib",
        "README.md",
        "LICENSE",
        "LICENSE.txt",
        "LICENSE.md",
        "mix.exs"
      ],
      maintainers: ["Finite Field, K.K."],
      keywords: ["pii", "masking", "email", "phone", "privacy"]
    ]
  end
end
