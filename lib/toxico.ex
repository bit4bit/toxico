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

  @spec add_bootstrap(GenServer.name(), String.t(), integer(), String.t()) :: :ok | {:error, :null} | {:error, :bad_host} | {:error, :port}
  def add_bootstrap(name, host, port, public_key) when is_binary(host) and is_integer(port) and is_binary(public_key) do
    GenServer.call(name, {:add_boostrap, host, port, public_key}, 60_000)
  end

  # callbacks

  @impl true
  def init(_opts) do
    {:ok, cnode} = Unifex.CNode.start_link(:tox)
    :ok = call(cnode, :init)

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

  @impl true
  def handle_call({:add_boostrap, host, port, public_key}, _from, state) do
    reply = call(state.cnode, :bootstrap, [host, port, public_key])
    {:reply, reply, state}
  end

  defp call(cnode, fun, args \\ [], timeout \\ 5000) do
    Unifex.CNode.call(cnode, fun, args, timeout)
  end
end
