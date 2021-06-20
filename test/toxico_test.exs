defmodule ToxicoTest do
  use ExUnit.Case, async: false
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

  describe "bootstrap" do

    test "single node tox" do
      tox = start_supervised!({Toxico, []})

      host = "tox1.mf-net.eu"
      port = 33_445
      public_key = "B3E5FA80DC8EBD1149AD2AB35ED8B85BD546DEDE261CA593234C619249419506"

      :ok = Toxico.add_bootstrap(tox, host, port, public_key)
    end
  end

  describe "identification" do
    test "set name" do
      tox = start_supervised!({Toxico, []})

      :ok = Toxico.set_name(tox, "Toxico")
    end

    test "get name" do
      tox = start_supervised!({Toxico, []})

      :ok = Toxico.set_name(tox, "Toxico")

      assert %{
        name: "Toxico"
      } = Toxico.self(tox)
    end

    test "set status message" do
      tox = start_supervised!({Toxico, []})

      :ok = Toxico.set_status_message(tox, "Toxico works!")
    end

    test "get status message" do
      tox = start_supervised!({Toxico, []})

      :ok = Toxico.set_status_message(tox, "Toxico works!")

      assert %{
        status_message: "Toxico works!"
      } = Toxico.self(tox)
    end
  end
end
