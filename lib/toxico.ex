defmodule Toxico do
  @moduledoc """
  Documentation for `Toxico`.
  """

  use GenServer

  require Unifex.CNode

  defmodule State do
    @moduledoc false

    defstruct [:cnode]
  end

  def start_link(opts \\ []) do
    {name, opts} = Keyword.pop(opts, :name, nil)

    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @spec version(GenServer.name()) :: Version.t() | nil
  def version(name) do
    GenServer.call(name, :version)
  end

  # callbacks

  @impl true
  def init(_opts) do
    {:ok, cnode} = Unifex.CNode.start_link(:tox)

    {:ok, %State{cnode: cnode}}
  end

  @impl true
  def handle_call(:version, _from, state) do
    {:ok, {major, minor, patch}} = call(state.cnode, :version)

    case Version.parse("#{major}.#{minor}.#{patch}") do
      {:ok, version} ->
        {:reply, version, state}

      _ ->
        {:reply, nil, state}
    end
  end

  defp call(cnode, fun, args \\ []) do
    Unifex.CNode.call(cnode, fun, args)
  end
end
