defmodule ContextTest do

  use ExUnit.Case, async: false
  import MetrixTestHelper

  setup do
    Metrix.clear_context()
  end

  test "context" do
    for context <- [%{"global" => "context"}, [global: "context"]] do
      Metrix.add_context(context)
      assert Metrix.get_context() == Enum.into(context, %{})
      Metrix.clear_context()
    end
  end

  test "adding to the context" do
    [c1, c2] = [%{"global1" => "context"}, [global2: "context"]]
    Metrix.add_context(c1)
    Metrix.add_context(c2)
    assert Metrix.get_context() == Enum.into(c1, Enum.into(c2, %{}))
  end

  test "context overrides" do
    [c1, c2] = [%{"global" => "context1"}, %{"global" => "context2"}]
    Metrix.add_context(c1)
    Metrix.add_context(c2)
    assert Metrix.get_context() == c2
  end

  test "initial context" do
    for context <- [%{"test_key" => "test_value"}, [test_key: "test_value"]] do
      with_initial_context(context, fn(context) ->
        assert Metrix.get_context() == Enum.into(context, %{})
      end)
    end
  end
end
