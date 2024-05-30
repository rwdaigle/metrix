ExUnit.start()

ExUnit.configure exclude: [:config]

defmodule MetrixTestHelper do

  import ExUnit.CaptureLog

  def line(fun), do: capture_log(fun) |> String.trim
  def silence(fun), do: capture_log(fun); nil

  def matches_measure?(output) do
    Regex.match?(~r/measure#event.name=[0-9]+\.*+[0-9]+ms/u, output)
  end
end
