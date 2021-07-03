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

  describe "self" do
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

    test "get status" do
      tox = start_supervised!({Toxico, []})

      :ok = Toxico.set_status(tox, :user_away)

      assert %{
        status: :user_away
      } = Toxico.self(tox)
    end

    test "get address" do
      tox = start_supervised!({Toxico, []})

      %{
        address: address
      } = Toxico.self(tox)

      assert address != ""
    end

    test "get nospam" do
      tox = start_supervised!({Toxico, []})

      %{
        nospam: nospam
      } = Toxico.self(tox)

      assert nospam > 0
    end
  end

  describe "friend" do
    test "delete" do
      tox = start_supervised!({Toxico, []})
      tox2 = start_supervised!({Toxico, []}, id: Toxico2)

      public_key = "3C31E5ADAFDD5483DA27DC0C05A9DF4350B63793B773FC083C2808CDC7086E6E"
      {:ok, friend_number} =  Toxico.add_friend_norequest(tox2, public_key)
      :ok = Toxico.delete_friend(tox2, friend_number)
    end
  end

end
