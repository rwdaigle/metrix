defmodule ContextTest do

  use ExUnit.Case, async: false
  import Application
  import MetrixTestHelper

  setup do
    Metrix.clear_context()
  end

  test "context" do
    for context <- [%{"global" => "context"}, [global: "context"]] do
      Metrix.add_context(context)
      assert Metrix.get_context() == context
      Metrix.clear_context()
    end
  end

  test "adding to the context" do
    [c1, c2] = [%{"global1" => "context"}, [global2: "context"]]
    Metrix.add_context(c1)
    Metrix.add_context(c2)
    assert Metrix.get_context() == Enum.into(c1, c2)
  end

  test "initial context" do
    with_initial_context(%{"test_key" => "test_value"}, fn(context) ->
      assert Metrix.get_context() == context
    end)
  end

  test "context output" do
    Metrix.add_context %{"parent" => "context"}
    metadata = %{"meta" => "data"}
    output = line(fn -> Metrix.count metadata, "event.name" end)
    assert output |> String.contains?("parent=context")
    assert output |> String.contains?("meta=data")
    assert output |> String.contains?("event.name=1")
  end

  # All the machinations needed to start an app with a known config
  defp with_initial_context(new_context, fun) do
    before_context = get_env(:metrix, :context)
    silence fn ->
      stop(:metrix)
      put_env(:metrix, :context, new_context)
      start(:metrix)
    end
    fun.(new_context)
    silence fn ->
      stop(:metrix)
      put_env(:metrix, :context, before_context)
      start(:metrix)
    end
  end
end
