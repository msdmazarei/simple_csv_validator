defmodule T1Test do
  use ExUnit.Case
  doctest T1

  test "greets the world" do
    assert T1.hello() == :world
  end
end
