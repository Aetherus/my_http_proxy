defmodule MyHttpProxyTest do
  use ExUnit.Case
  doctest MyHttpProxy

  test "greets the world" do
    assert MyHttpProxy.hello() == :world
  end
end
