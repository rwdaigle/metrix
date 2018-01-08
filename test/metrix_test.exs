defmodule MetrixTest do

  use ExUnit.Case, async: false
  import MetrixTestHelper

  setup do
    Metrix.clear_context
    Metrix.clear_prefix
  end

  test "basic count" do
    assert line(fn -> Metrix.count "event.name" end) == "count#event.name=1"
  end

  test "basic count with metadata" do
    for metadata <- [%{"meta" => "data"}, [meta: "data"]] do
      output = line(fn -> Metrix.count metadata, "event.name" end)
      assert output |> String.contains?("count#event.name=1")
      assert output |> String.contains?("meta=data")
      line(fn -> assert Metrix.count(metadata, "event.name") == metadata end)
    end
  end

  test "count with number" do
    assert line(fn -> Metrix.count "event.name", 23 end) == "count#event.name=23"
  end

  test "count with number and metadata" do
    for metadata <- [%{"meta" => "data"}, [meta: "data"]] do
      output = line(fn -> Metrix.count metadata, "event.name", 23 end)
      assert output |> String.contains?("count#event.name=23")
      assert output |> String.contains?("meta=data")
      line(fn -> assert Metrix.count(metadata, "event.name", 1) == metadata end)
    end
  end

  test "count with number and metadata and global context" do
    Metrix.add_context %{"meta" => "data_global"}
    for metadata <- [%{"meta" => "data"}, [meta: "data"]] do
      output = line(fn -> Metrix.count metadata, "event.name", 23 end)
      assert output |> String.contains?("count#event.name=23")
      assert output |> String.contains?("meta=data")
      line(fn -> assert Metrix.count(metadata, "event.name", 1) == metadata end)
    end
  end

  test "sample" do
    assert line(fn -> Metrix.sample "event.name", "13.4mb" end) == "sample#event.name=13.4mb"
  end

  test "sample with metadata" do
    for metadata <- [%{"meta" => "data"}, [meta: "data"]] do
      output = line(fn -> Metrix.sample metadata, "event.name", "13.4mb" end)
      assert output |> String.contains?("sample#event.name=13.4mb")
      assert output |> String.contains?("meta=data")
      line(fn -> assert Metrix.sample(metadata, "event.name", "13.4mb") == metadata end)
    end
  end

  test "sample with metadata and global context" do
    Metrix.add_context %{"meta" => "data_global"}
    for metadata <- [%{"meta" => "data"}, [meta: "data"]] do
      output = line(fn -> Metrix.sample metadata, "event.name", "13.4mb" end)
      assert output |> String.contains?("sample#event.name=13.4mb")
      assert output |> String.contains?("meta=data")
      line(fn -> assert Metrix.sample(metadata, "event.name", "13.4mb") == metadata end)
    end
  end

  test "measure function latency" do
    output = line(fn -> Metrix.measure "event.name", fn -> :timer.sleep(1) end end)
    assert matches_measure?(output), "Unexpected output format \"#{output}\""
  end

  test "measure w/ pre-computed latency" do
    output = line(fn -> Metrix.measure "event.name", 0.912 end)
    assert matches_measure?(output), "Unexpected output format \"#{output}\""
    assert output |> String.contains?("=0.912ms"), "Incorrect measurement value"
  end

  test "measure function latency with metadata" do
    for metadata <- [%{"meta" => "data"}, [meta: "data"]] do
      output = line(fn -> Metrix.measure metadata, "event.name", fn -> :timer.sleep(1) end end)
      assert matches_measure?(output), "Unexpected output format \"#{output}\""
      assert output |> String.contains?("meta=data")
    end
  end

  test "measure w/ pre-computed latency with metadata" do
    for metadata <- [%{"meta" => "data"}, [meta: "data"]] do
      output = line(fn -> Metrix.measure metadata, "event.name", 12.34 end)
      assert matches_measure?(output), "Unexpected output format \"#{output}\""
      assert output |> String.contains?("meta=data")
      assert output |> String.contains?("=12.34ms"), "Incorrect measurement value"
    end
  end

  test "measure function latency with map metadata passed to function" do
    metadata = %{"meta" => "data"}
    output = line(fn -> Metrix.measure metadata, "event.name", fn %{"meta" => _data} -> :timer.sleep(1) end end)
    assert matches_measure?(output), "Unexpected output format \"#{output}\""
    assert output |> String.contains?("meta=data")
  end

  test "measure function latency with keyword list metadata passed to function" do
    metadata = [meta: "data"]
    output = line(fn -> Metrix.measure metadata, "event.name", fn [meta: _data] -> :timer.sleep(1) end end)
    assert matches_measure?(output), "Unexpected output format \"#{output}\""
    assert output |> String.contains?("meta=data")
  end

  test "measure function latency with metadata and global context" do
    Metrix.add_context %{"meta" => "data_global"}
    for metadata <- [%{"meta" => "data"}, [meta: "data"]] do
      output = line(fn -> Metrix.measure metadata, "event.name", fn -> :timer.sleep(1) end end)
      assert matches_measure?(output), "Unexpected output format \"#{output}\""
      assert output |> String.contains?("meta=data")
    end
  end

  test "measure pre-computed latency with metadata and global context" do
    Metrix.add_context %{"meta" => "data_global"}
    for metadata <- [%{"meta" => "data"}, [meta: "data"]] do
      output = line(fn -> Metrix.measure metadata, "event.name", 78 end)
      assert matches_measure?(output), "Unexpected output format \"#{output}\""
      assert output |> String.contains?("meta=data")
      assert output |> String.contains?("=78ms"), "Incorrect measurement value"
    end
  end

  test "count with prefix" do
    Metrix.put_prefix("prefix-")
    assert line(fn -> Metrix.count "event.name" end) == "count#prefix-event.name=1"
  end

  test "measure with prefix" do
    Metrix.put_prefix("prefix-")
    output = line(fn -> Metrix.measure "event.name", fn -> :timer.sleep(1) end end)
    assert Regex.match?(~r/measure#prefix-event.name=[0-9]+\.+[0-9]+ms/u, output)
  end

  test "sample with prefix" do
    Metrix.put_prefix("prefix-")
    assert line(fn -> Metrix.sample "event.name", "13.4mb" end) == "sample#prefix-event.name=13.4mb"
  end

end
