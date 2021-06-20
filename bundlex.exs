defmodule Toxico.BundlexProject do
  use Bundlex.Project

  def project() do
    [
      natives: natives(Bundlex.platform())
    ]
  end

  def natives(:linux) do
    [
      tox: [
        sources: ["tox.c"],
        interface: [:cnode],
        preprocessor: Unifex
      ]
    ]
  end
end
