defmodule CarRentalTest do
  use ExUnit.Case
  doctest CarRental

  test "greets the world" do
    assert CarRental.hello() == :world
  end
end
