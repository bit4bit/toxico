defmodule Toxico do
  @moduledoc """
  Documentation for `Toxico`.
  """

  use GenServer

  require Unifex.CNode
  require Logger

  defmodule State do
    @moduledoc false

    defstruct [:cnode, :handler]
  end

  defmodule Self do
    @moduledoc false

    defstruct [:name, :status_message, :status, :address, :nospam]
  end

  def start_link(opts \\ []) do
    {name, opts} = Keyword.pop(opts, :name, nil)
    opts = Keyword.put_new(opts, :handler, self())

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

  @spec add_friend(GenServer.name(), String.t(), String) :: {:ok, integer()} | {:error, atom()}
  def add_friend(name, address, message) do
    GenServer.call(name, {:add_friend, address, message})
  end

  def add_friend_norequest(name, public_key) do
    GenServer.call(name, {:add_friend_norequest, public_key})
  end

  def send_message_friend(name, friend_number, message) do
    GenServer.call(name, {:send_message_friend, friend_number, :message_normal, message})
  end

  # bit4bit temporary only for testing
  def add_default_bootstrap(name) do
    dhts = [
      {"185.25.116.107", 33_445, "DA4E4ED4B697F2E9B000EEFE3A34B554ACD3F45F5C96EAEA2516DD7FF9AF7B43"},
      {"79.140.30.52", 33_445, "FFAC871E85B1E1487F87AE7C76726AE0E60318A85F6A1669E04C47EB8DC7C72D"},
      {"46.101.197.175", 443, "CD133B521159541FB1D326DE9850F5E56A6C724B5B8E5EB5CD8D950408E95707"}
    ]

    for {host, port, public_key} <- dhts do
      add_bootstrap(name, host, port, public_key)
    end
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
  def init(opts) do
    handler = Keyword.get(opts, :handler)

    {:ok, cnode} = Unifex.CNode.start_link(:tox)
    :ok = call(cnode, :init)

    {:ok, %State{cnode: cnode, handler: handler}}
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
    address = call(state.cnode, :self_get_address)
    nospam = call(state.cnode, :self_get_nospam)

    self = %{
      name: name,
      status_message: message,
      status: status,
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
  def handle_call({:add_friend_norequest, public_key}, _from, state) do
    reply = call(state.cnode, :friend_add_norequest, [public_key])
    {:reply, reply, state}
  end
  def handle_call({:add_friend, address, message}, _from, state) do
    reply = call(state.cnode, :friend_add, [address, message])
    {:reply, reply, state}
  end
  def handle_call({:send_message_friend, friend_number, message_type, message}, _from, state) do
    reply = call(state.cnode, :friend_send_message, [friend_number, message_type, message])
    {:reply, reply, state}
  end

  @impl true
  def handle_info({:friend_message, friend_number, message}, state) do
    Logger.info "friend #{friend_number} message: #{message}"

    send(state.handler, {self(), :friend_message, friend_number, message})

    {:noreply, state}
  end
  def handle_info({:friend_request, public_key, message}, state) do
    Logger.info "friend request: #{public_key} #{message}"

    send(state.handler, {self(), :friend_request, public_key, message})

    {:noreply, state}
  end
  def handle_info({:connection_status, status}, state) do
    Logger.info "connection status: #{status}"

    send(state.handler, {self(), :connection_status, status})

    {:noreply, state}
  end

  defp call(cnode, fun, args \\ [], timeout \\ 5000) do
    Unifex.CNode.call(cnode, fun, args, timeout)
  end
end
