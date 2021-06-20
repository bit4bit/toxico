defmodule ToxicoTest do
  use ExUnit.Case
  doctest Toxico

  describe "start link" do
    test "start as registered GenServer", config do
      start_supervised!({Toxico, name: config.test})

      assert Process.whereis(config.test)
    end

    test "start GenServer" do
      pid = start_supervised!({Toxico, []})

      assert is_pid(pid)
    end
  end

  describe "version" do
    test "match version" do
      tox = start_supervised!({Toxico, []})

      Version.match?(Toxico.version(tox), ">= 0.2.29")
    end
  end
end
