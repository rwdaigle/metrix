ExUnit.start()

ExUnit.configure exclude: [:config]

# Streamline logger output to just the message for easier testing
Logger.configure_backend :console,
  level: :info,
  format: "$message\n",
  colors: [enabled: false]

defmodule MetrixTestHelper do

  import ExUnit.CaptureLog

  def line(fun), do: capture_log(fun) |> String.strip
  def silence(fun), do: capture_log(fun); nil

  def matches_measure?(output) do
    Regex.match?(~r/measure#event.name=[0-9]+\.*+[0-9]+ms/u, output)
  end
end
