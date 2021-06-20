defmodule ToxicoTest do
  use ExUnit.Case
  doctest Toxico

  test "greets the world" do
    assert Toxico.hello() == :world
  end
end
