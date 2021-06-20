module Tox

interface CNode


spec version() :: {:ok :: label, { major :: int, minor :: int, patch :: int}} | :error
