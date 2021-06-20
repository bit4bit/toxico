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
        sources: ["tox.c", "tools.c"],
        pkg_configs: ["toxcore"],
        libs: ["pthread"],
        interface: [:cnode],
        preprocessor: Unifex
      ]
    ]
  end
end
