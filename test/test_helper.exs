ExUnit.start()

ExUnit.configure exclude: [:config]

defmodule MetrixTestHelper do

  import Application
  import ExUnit.CaptureLog

  def line(fun), do: capture_log(fun) |> String.trim
  def silence(fun), do: capture_log(fun); nil

  def matches_measure?(output, event), do: matches_measure?(output, event, "")
  def matches_measure?(output, event, prefix) do
    Regex.match?(~r/^measure##{prefix}#{event}=[0-9]+\.*+[0-9]+ms/u, output)
  end

  def matches_count?(output, event), do: matches_count?(output, event, "")
  def matches_count?(output, event, prefix) do
    Regex.match?(~r/^count##{prefix}#{event}=[0-9]+/u, output)
  end

  def matches_sample?(output, event), do: matches_sample?(output, event, "")
  def matches_sample?(output, event, prefix) do
    Regex.match?(~r/^sample##{prefix}#{event}=[0-9]+/u, output)
  end

  # All the machinations needed to start an app with a known config
  def with_initial_context(new_context, fun) do
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
