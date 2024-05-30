defmodule MetrixTest do

  use ExUnit.Case, async: false
  import MetrixTestHelper

  setup do
    Metrix.clear_context
    Metrix.clear_prefix
  end

  describe "count" do

    test "with no args" do
      for event <- ["event_name", :event_name] do
        assert line(fn -> Metrix.count(event) end) == "count#event_name=1"
      end
    end

    test "with prefix" do
      Metrix.put_prefix("prefix-")
      assert line(fn -> Metrix.count "event.name" end) == "count#prefix-event.name=1"
    end

    test "with metadata" do
      for metadata <- [%{"meta" => "data"}, [meta: "data"]] do
        for event <- ["event_name", :event_name] do
          output = line(fn -> Metrix.count(metadata, event) end)
          assert output |> String.contains?("count#event_name=1")
          assert output |> String.contains?("meta=data")
          line(fn -> assert Metrix.count(metadata, event) == metadata end)
        end
      end
    end

    test "with number" do
      for event <- ["event_name", :event_name] do
        assert line(fn -> Metrix.count(event, 23) end) == "count#event_name=23"
      end
    end

    test "with number and metadata" do
      for metadata <- [%{"meta" => "data"}, [meta: "data"]] do
        for event <- ["event_name", :event_name] do
          output = line(fn -> Metrix.count(metadata, event, 23) end)
          assert output |> String.contains?("count#event_name=23")
          assert output |> String.contains?("meta=data")
          line(fn -> assert Metrix.count(metadata, event, 1) == metadata end)
        end
      end
    end

    test "with number, metadata, and global context" do
      for context <- [%{"context" => "global"}, [context: "global"]] do
        Metrix.add_context(context)
        for metadata <- [%{"meta" => "data"}, [meta: "data"]] do
          for event <- ["event_name", :event_name] do
            output = line(fn -> Metrix.count(metadata, event, 23) end)
            assert output |> String.contains?("count#event_name=23")
            assert output |> String.contains?("meta=data")
            assert output |> String.contains?("context=global")
          end
        end
        Metrix.clear_context()
      end
    end
  end

  describe "sample" do

    test "default" do
      for event <- ["event_name", :event_name] do
        assert line(fn -> Metrix.sample(event, "13.4mb") end) == "sample#event_name=13.4mb"
      end
    end

    test "with prefix" do
      Metrix.put_prefix("prefix-")
      for event <- ["event_name", :event_name] do
        assert line(fn -> Metrix.sample(event, "13.4mb") end) == "sample#prefix-event_name=13.4mb"
      end
    end

    test "with metadata" do
      for metadata <- [%{"meta" => "data"}, [meta: "data"]] do
        for event <- ["event_name", :event_name] do
          output = line(fn -> Metrix.sample metadata, event, "13.4mb" end)
          assert output |> String.contains?("sample#event_name=13.4mb")
          assert output |> String.contains?("meta=data")
          line(fn -> assert Metrix.sample(metadata, event, "13.4mb") == metadata end)
        end
      end
    end

    test "with metadata and global context" do
      for context <- [%{"context" => "global"}, [context: "global"]] do
        Metrix.add_context(context)
        for metadata <- [%{"meta" => "data"}, [meta: "data"]] do
          for event <- ["event_name", :event_name] do
            output = line(fn -> Metrix.sample(metadata, event, "13.4mb") end)
            assert output |> String.contains?("sample#event_name=13.4mb")
            assert output |> String.contains?("meta=data")
            assert output |> String.contains?("context=global")
          end
        end
        Metrix.clear_context()
      end
    end
  end

  describe "measure" do

    test "function latency" do
      for event <- ["event_name", :event_name] do
        output = line(fn -> Metrix.measure(event, fn -> :timer.sleep(1) end) end)
        assert matches_measure?(output, event), "Unexpected output format \"#{output}\""
      end
    end

    test "with prefix" do
      Metrix.put_prefix("prefix-")
      for event <- ["event_name", :event_name] do
        output = line(fn -> Metrix.measure(event, fn -> :timer.sleep(1) end) end)
        assert matches_measure?(output, event, "prefix-"), "Unexpected output format \"#{output}\""
      end
    end

    test "with pre-computed latency" do
      for event <- ["event_name", :event_name] do
        output = line(fn -> Metrix.measure(event, 0.912) end)
        assert matches_measure?(output, event), "Unexpected output format \"#{output}\""
        assert output |> String.contains?("=0.912ms"), "Incorrect measurement value"
      end
    end

    test "with metadata" do
      for metadata <- [%{"meta" => "data"}, [meta: "data"]] do
        for event <- ["event_name", :event_name] do
          output = line(fn -> Metrix.measure(metadata, event, fn -> :timer.sleep(1) end) end)
          assert matches_measure?(output, event), "Unexpected output format \"#{output}\""
          assert output |> String.contains?("meta=data")
        end
      end
    end

    test "with pre-computed latency and metadata" do
      for metadata <- [%{"meta" => "data"}, [meta: "data"]] do
        for event <- ["event_name", :event_name] do
          output = line(fn -> Metrix.measure(metadata, event, 12.34) end)
          assert matches_measure?(output, event), "Unexpected output format \"#{output}\""
          assert output |> String.contains?("meta=data")
          assert output |> String.contains?("=12.34ms"), "Incorrect measurement value"
        end
      end
    end

    test "with map metadata passed to function" do
      metadata = %{"meta" => "data"}
      output = line(fn -> Metrix.measure(metadata, "event.name", fn %{"meta" => _data} -> :timer.sleep(1) end) end)
      assert matches_measure?(output), "Unexpected output format \"#{output}\""
      assert output |> String.contains?("meta=data")
    end

    test "with keyword list metadata passed to function" do
      metadata = [meta: "data"]
      output = line(fn -> Metrix.measure(metadata, "event.name", fn [meta: _data] -> :timer.sleep(1) end) end)
      assert matches_measure?(output), "Unexpected output format \"#{output}\""
      assert output |> String.contains?("meta=data")
    end

    test "with metadata and global context" do
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
  end
end
