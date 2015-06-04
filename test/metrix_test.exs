defmodule MetrixTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "basic count" do
    assert line(fn -> Metrix.count "event.name" end) == "count#event.name=1"
  end

  test "basic count with metadata" do
    metadata = %{"meta" => "data"}
    output = line(fn -> Metrix.count metadata, "event.name" end)
    assert output |> String.contains?("count#event.name=1")
    assert output |> String.contains?("meta=data")
  end

  test "count with number" do
    assert line(fn -> Metrix.count "event.name", 23 end) == "count#event.name=23"
  end

  test "count with number and metadata" do
    metadata = %{"meta" => "data"}
    output = line(fn -> Metrix.count metadata, "event.name", 23 end)
    assert output |> String.contains?("count#event.name=23")
    assert output |> String.contains?("meta=data")
  end

  test "sample" do
    assert line(fn -> Metrix.sample "event.name", "13.4mb" end) == "sample#event.name=13.4mb"
  end

  test "sample with metadata" do
    metadata = %{"meta" => "data"}
    output = line(fn -> Metrix.sample metadata, "event.name", "13.4mb" end)
    assert output |> String.contains?("sample#event.name=13.4mb")
    assert output |> String.contains?("meta=data")
  end

  test "measure" do
    output = line(fn -> Metrix.measure "event.name", fn -> :timer.sleep(1) end end)
    assert matches_measure?(output), "Unexpected output format \"#{output}\""
  end

  test "measure with metadata" do
    metadata = %{"meta" => "data"}
    output = line(fn -> Metrix.measure metadata, "event.name", fn -> :timer.sleep(1) end end)
    assert matches_measure?(output), "Unexpected output format \"#{output}\""
    assert output |> String.contains?("meta=data")
  end

  test "measure with metadata passed to function" do
    metadata = %{"meta" => "data"}
    output = line(fn -> Metrix.measure metadata, "event.name", fn %{"meta" => data} -> :timer.sleep(1) end end)
    assert matches_measure?(output), "Unexpected output format \"#{output}\""
    assert output |> String.contains?("meta=data")
  end

  defp line(fun), do: capture_io(fun) |> String.strip

  defp matches_measure?(output) do
    Regex.match?(~r/measure#event.name=[0-9]+\.+[0-9]+ms/u, output)
  end
end
