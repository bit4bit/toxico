module Tox

interface CNode

state_type "State"

spec init() :: {:ok :: label, state}

spec version() :: {:ok :: label, { major :: unsigned, minor :: unsigned, patch :: unsigned}} | :error

spec bootstrap(host :: string, port :: unsigned, hex_public_key :: string) :: :ok | {:error :: label, atom()}

spec self_set_name(name :: string) :: :ok | {:error :: label, atom()}
spec self_get_name() :: {:ok :: label,  name :: string}

spec self_set_status_message(message :: string) :: :ok | {:error :: label, atom()}
spec self_get_status_message() :: {:ok :: label,  message :: string}

type user_status :: :user_none | :user_busy | :user_away

spec self_set_status(status :: user_status) :: :ok
spec self_get_status() :: user_status
