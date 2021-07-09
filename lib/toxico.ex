defmodule Toxico do
  @moduledoc """
  Toxico bindings for ctox-core using Unifex.
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

  @doc "tox api version"
  @spec version(GenServer.name()) :: Version.t() | nil
  def version(name) do
    GenServer.call(name, :version)
  end

  @doc """
  Sends a "get nodes" request to the given bootstrap node with IP, port, and public key to setup connections.
  """
  @spec add_bootstrap(GenServer.name(), String.t(), integer(), String.t()) :: :ok | {:error, :null} | {:error, :bad_host} | {:error, :port}
  def add_bootstrap(name, host, port, public_key) when is_binary(host) and is_integer(port) and is_binary(public_key) do
    GenServer.call(name, {:add_boostrap, host, port, public_key}, 60_000)
  end

  @doc """
  Add a friend to the friend list and send a friend request.
  """
  @spec add_friend(GenServer.name(), String.t(), String) :: {:ok, integer()} | {:error, atom()}
  def add_friend(name, address, message) do
    GenServer.call(name, {:add_friend, address, message})
  end


  @doc """
  Add a friend without sending a friend request.
  """
  @spec add_friend_norequest(GenServer.name(), String.t) :: {:ok, integer()} | {:error, atom()}
  def add_friend_norequest(name, public_key) do
    GenServer.call(name, {:add_friend_norequest, public_key})
  end

  @doc """
  Add a friend without sending a friend request.
  """
  @spec delete_friend(GenServer.name(), integer()) :: :ok | {:error, atom()}
  def delete_friend(name, friend_number) when is_integer(friend_number) do
    GenServer.call(name, {:delete_friend, friend_number})
  end

  @doc """
  Send a text chat message to an online friend.
  """
  @spec send_message_friend(GenServer.name(), integer(), String.t) :: :ok | {:error, atom()}
  def send_message_friend(name, friend_number, message) do
    GenServer.call(name, {:send_message_friend, friend_number, :message_normal, message})
  end

  @doc """
  Friend name
  """
  @spec friend_name(GenServer.name(), integer()) :: {:ok, String.t()} | {:error, atom()}
  def friend_name(name, friend_number) when is_integer(friend_number) do
    GenServer.call(name, {:friend_name, friend_number})
  end

  @doc """
  Status message of the friend
  """
  @spec friend_status_message(GenServer.name(), integer()) :: {:ok, String.t()} | {:error, atom()}
  def friend_status_message(name, friend_number) when is_integer(friend_number) do
    GenServer.call(name, {:friend_status_message, friend_number})
  end

  @doc """
  Set the nickname for the Tox client.
  """
  @spec set_name(GenServer.name(), String.t()) :: :ok | {:error, atom()}
  def set_name(tox, name) do
    GenServer.call(tox, {:set_name, name})
  end

  @doc """
  Set the client's status message.
  """
  @spec set_status_message(GenServer.name(), String.t()) :: :ok | {:error, atom()}
  def set_status_message(tox, message) do
    GenServer.call(tox, {:set_status_message, message})
  end

  @doc """
  Set the client's status.
  """
  @spec set_status(GenServer.name(), :user_none | :user_away | :user_busy) :: :ok
  def set_status(tox, status) when is_atom(status) do
    GenServer.call(tox, {:set_status, status})
  end

  @doc """
  Query self client information.
  """
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
  def handle_call({:delete_friend, friend_number}, _from, state) do
    reply = call(state.cnode, :friend_delete, [friend_number])
    {:reply, reply, state}
  end
  def handle_call({:send_message_friend, friend_number, message_type, message}, _from, state) do
    reply = call(state.cnode, :friend_send_message, [friend_number, message_type, message])
    {:reply, reply, state}
  end
  def handle_call({:friend_name, friend_number}, _from, state) do
    reply = call(state.cnode, :friend_get_name, [friend_number])
    {:reply, reply, state}
  end
  def handle_call({:friend_status_message, friend_number}, _from, state) do
    reply = call(state.cnode, :friend_get_status_message, [friend_number])
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
  def handle_info({:friend_status, friend_number, status}, state) do
    Logger.info "friend_status: #{friend_number} #{status}"

    send(state.handler, {self(), :friend_status, friend_number, status})

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
