defmodule PchatTest do
  use ExUnit.Case
  doctest Pchat

  test "greets the world" do
    assert Pchat.hello() == :world
  end
end
