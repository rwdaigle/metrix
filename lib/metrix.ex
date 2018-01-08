require Logger

defmodule Metrix do
  use Application
  alias Metrix.Context
  alias Metrix.Modifiers

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Context, [initial_context()]),
      worker(Modifiers, [initial_modifiers()])
    ]

    opts = [strategy: :one_for_one, name: Metrix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp initial_context do
    case Application.get_env(:metrix, :context) do
      nil -> %{}
      context -> context
    end
  end

  defp initial_modifiers do
    case Application.get_env(:metrix, :prefix) do
      nil -> %{}
      prefix -> %{:prefix => prefix}
    end
  end

  @doc """
  Adds `metadata` to the global context, which will add the metadata values
  to all subsequent metrix output. Global context is useful for component-wide
  values, such as source=X or app=Y metadata, that remains unchanged throughout
  the life of your application.
  """
  def add_context(metadata), do: Context.put(metadata)
  def get_context, do: Context.get
  def clear_context, do: Context.clear

  @doc """
  The `prefix` is prepended to the name of the metric.
  """
  def put_prefix(prefix), do: Modifiers.put_prefix(prefix)
  def clear_prefix, do: Modifiers.clear_prefix

  def count(metric), do: count(metric, 1)
  def count(metric, num) when is_number(num), do: count(%{}, metric, num)
  def count(metadata, metric), do: count(metadata, metric, 1)
  def count(metadata, metric, num) do
    metadata
    |> add("count", metric, num)
    |> log

    metadata
  end

  def sample(metric, value), do: sample(%{}, metric, value)
  def sample(metadata, metric, value) do
    metadata
    |> add("sample", metric, value)
    |> log

    metadata
  end

  def measure(metric, ms) when is_number(ms), do: measure(%{}, metric, ms)
  def measure(metadata, metric, ms) when is_number(ms) do
    metadata
    |> add("measure", metric, "#{ms}ms")
    |> log
  end

  def measure(metric, fun) when is_function(fun), do: measure(%{}, metric, fun)
  def measure(metadata, metric, fun) when is_function(fun) do

    {service_us, ret_value} = cond do
      is_function(fun, 0) -> :timer.tc(fun)
      is_function(fun, 1) -> :timer.tc(fun, [metadata])
    end

    metadata
    |> add("measure", metric, "#{service_us / 1000}ms")
    |> log

    ret_value
  end

  def log(values) do
    Dict.merge(get_context(), values)
    |> Logfmt.encode
    |> write
  end

  defp add(dict, type, metric, value) do
    dict |> Dict.put(prefix_metric(type, metric), value)
  end

  defp prefix_metric(type, metric) do
    case Modifiers.get_prefix do
      nil -> :"#{type}##{metric}"
      _ -> :"#{type}##{Modifiers.get_prefix}#{metric}"
    end
  end

  defp write(output), do: output |> Logger.info
end
