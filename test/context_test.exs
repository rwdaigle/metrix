defmodule ContextTest do
  use ExUnit.Case

  @moduletag :config

  test "configured context" do
    assert Metrix.get_context == %{"test_key" => "test_value"}
  end
end
