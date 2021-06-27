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

  defmodule Self do
    @moduledoc false

    defstruct [:name, :status_message, :status, :connection_status, :address, :nospam]
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

  def set_name(tox, name) do
    GenServer.call(tox, {:set_name, name})
  end

  @spec set_status_message(GenServer.name(), String.t()) :: :ok | {:error, atom()}
  def set_status_message(tox, message) do
    GenServer.call(tox, {:set_status_message, message})
  end

  @spec set_status(GenServer.name(), :user_none | :user_away | :user_busy) :: :ok
  def set_status(tox, status) when is_atom(status) do
    GenServer.call(tox, {:set_status, status})
  end

  @spec self(GenServer.name()) :: %Self{}
  def self(name) do
    GenServer.call(name, :self)
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
  def handle_call({:add_boostrap, host, port, public_key}, _from, state) do
    reply = call(state.cnode, :bootstrap, [host, port, public_key])
    {:reply, reply, state}
  end
  def handle_call(:self, _from, state) do
    name = call(state.cnode, :self_get_name)
    message = call(state.cnode, :self_get_status_message)
    status = call(state.cnode, :self_get_status)
    connection_status = call(state.cnode, :self_get_connection_status)
    address = call(state.cnode, :self_get_address)
    nospam = call(state.cnode, :self_get_nospam)

    self = %{
      name: name,
      status_message: message,
      status: status,
      connection_status: connection_status,
      address: address,
      nospam: nospam
    }

    {:reply, struct(Self, self), state}
  end
  def handle_call({:set_name, name}, _from, state) do
    reply = call(state.cnode, :self_set_name, [name])

    {:reply, reply, state}
  end
  def handle_call({:set_status_message, message}, _from, state) do
    reply = call(state.cnode, :self_set_status_message, [message])

    {:reply, reply, state}
  end
  def handle_call({:set_status, status}, _from, state) do
    reply = call(state.cnode, :self_set_status, [status])

    {:reply, reply, state}
  end

  defp call(cnode, fun, args \\ [], timeout \\ 5000) do
    Unifex.CNode.call(cnode, fun, args, timeout)
  end
end
