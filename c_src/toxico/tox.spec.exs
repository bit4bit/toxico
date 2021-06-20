module Tox

interface CNode

state_type "State"

spec init() :: {:ok :: label, state}

spec version() :: {:ok :: label, { major :: unsigned, minor :: unsigned, patch :: unsigned}} | :error
