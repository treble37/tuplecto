defmodule TuplectoTest do
  use ExUnit.Case
  doctest Tuplecto

  test "greets the world" do
    assert Tuplecto.hello() == :world
  end
end
