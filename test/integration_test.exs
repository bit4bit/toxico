defmodule IntegrationToxicoTest do
  use ExUnit.Case, async: false

  describe "bootstrap" do

    test "single node tox" do
      tox = start_supervised!({Toxico, []})

      host = "tox1.mf-net.eu"
      port = 33_445
      public_key = "B3E5FA80DC8EBD1149AD2AB35ED8B85BD546DEDE261CA593234C619249419506"

      :ok = Toxico.add_bootstrap(tox, host, port, public_key)
    end
  end

  describe "conversation" do
    test "chat flow" do
      pid = self()
      tox = start_supervised!({Toxico, [handler: pid]})
      tox2 = start_supervised!({Toxico, [handler: pid]}, id: Toxico2)
      :ok = Toxico.set_name(tox, "toxico1")
      :ok = Toxico.set_status_message(tox, "toxico1 status message")
      :ok = Toxico.set_name(tox2, "toxico2")
      :ok = Toxico.set_status_message(tox2, "toxico2 status message")

      receive do
        {^tox2, :connection_status, _} ->
          :ok
        {^tox, :connection_status, _} ->
          :ok
      after 15_000 ->
          raise "timeout"
      end

      receive do
        {^tox2, :connection_status, _} ->
          :ok
        {^tox, :connection_status, _} ->
          :ok
      after 15_000 ->
          raise "timeout"
      end

      # send friend reuest
      tox2_self = Toxico.self(tox2)
      {:ok, tox2_friend} = Toxico.add_friend(tox, tox2_self.address, "hola tox2")
      assert_receive {^tox2, :friend_request, public_key, "hola tox2"}, 5000

      # get friend request and add friend
      {:ok, friend_number} = Toxico.add_friend_norequest(tox2, public_key)

      :timer.sleep(3_000)
      :ok = Toxico.set_typing(tox2, friend_number, :start)
      assert_receive {^tox, :friend_typing, ^tox2_friend, :start}

      # send message
      :ok = Toxico.send_message_friend(tox2, friend_number, "hola desde tox2")
      assert_receive {^tox, :friend_message, _, "hola desde tox2"}, 10_000

      # send message
      :ok = Toxico.send_message_friend(tox, tox2_friend, "hola desde tox")
      assert_receive {^tox2, :friend_message, _, "hola desde tox"}, 10_000

      # get friend name
      {:ok, friend_name} = Toxico.friend_name(tox2, friend_number)
      assert friend_name == "toxico1"

      # get friend status message
      {:ok, friend_status_message} = Toxico.friend_status_message(tox2, friend_number)
      assert friend_status_message == "toxico1 status message"

      :ok = Toxico.set_status(tox, :user_away)
      assert_receive {^tox2, :friend_status, _, :user_away}, 5_000
    end
  end
end
