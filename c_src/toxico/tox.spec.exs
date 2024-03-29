module Tox

interface CNode

state_type "State"

spec init() :: {:ok :: label, state}

spec version() :: {:ok :: label, { major :: unsigned, minor :: unsigned, patch :: unsigned}} | :error

spec bootstrap(host :: string, port :: unsigned, hex_public_key :: string) :: :ok | {:error :: label, atom()}

spec self_set_name(name :: string) :: :ok | {:error :: label, atom()}
spec self_get_name() :: name :: string

spec self_set_status_message(message :: string) :: :ok | {:error :: label, atom()}
spec self_get_status_message() ::  message :: string

type user_status :: :user_none | :user_busy | :user_away

spec self_set_status(status :: user_status) :: :ok
spec self_get_status() :: user_status

type connection_status :: :connection_none | :connection_tcp | :connection_udp

spec self_get_address() :: string
spec self_get_nospam() :: nospam :: unsigned

sends {:friend_request :: label, public_key :: string, message :: string}
sends {:connection_status :: label, status :: connection_status}
sends {:friend_request_error :: label, message :: string}
sends {:friend_status :: label, friend_number :: unsigned, status :: user_status}
sends {:friend_connection_status :: label, friend_number :: unsigned, status :: connection_status}

spec friend_add_norequest(hex_public_key :: string) :: {:ok, friend_number :: unsigned} | {:error :: label, atom()}
spec friend_delete(friend_number :: unsigned) :: :ok | {:error :: label, atom()}
spec friend_add(hex_address :: string, message :: string) :: {:ok, friend_number :: unsigned} | {:error :: label, atom()}
spec friend_get_name(friend_number :: unsigned) :: {:ok, string} | {:error :: label, atom()}
spec friend_get_status_message(friend_number :: unsigned) :: {:ok, string} | {:error ::label, atom()}
type message_type :: :message_normal | :message_action

sends {:friend_message :: label, friend_number :: unsigned, message :: string}
spec friend_send_message(friend_number :: unsigned, type :: message_type, message :: string) :: :ok | {:error :: label, atom()}

sends {:friend_typing :: label, friend_number :: unsigned, is_typing :: bool}
spec self_set_typing(friend_number :: unsigned, is_typing :: bool) :: :ok | {:error :: label, atom()}
