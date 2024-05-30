require Logger

defmodule Metrix do

  use Application
  alias Metrix.Context
  alias Metrix.Modifiers

  def start(_type, _args) do
    children = [
      %{
        id: Context,
        start: {Context, :start_link, [initial_context()]},
        type: :supervisor,
        shutdown: :infinity
      },
      %{
        id: Modifiers,
        start: {Modifiers, :start_link, [initial_modifiers()]},
        type: :supervisor,
        shutdown: :infinity
      }
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
  def get_context, do: Context.get()
  def clear_context, do: Context.clear()

  @doc """
  The `prefix` is prepended to the name of the metric.
  """
  def put_prefix(prefix), do: Modifiers.put_prefix(prefix)
  def clear_prefix, do: Modifiers.clear_prefix()

  def count(metric), do: count(metric, 1)
  def count(metric, num) when is_number(num), do: count(%{}, metric, num)
  def count(metadata, metric), do: count(metadata, metric, 1)
  def count(metadata, metric, num) do
    log(format_metric("count", metric, num), metadata)
    metadata
  end

  def sample(metric, value), do: sample(%{}, metric, value)
  def sample(metadata, metric, value) do
    log(format_metric("sample", metric, value), metadata)
    metadata
  end

  def measure(metric, ms) when is_number(ms), do: measure(%{}, metric, ms)
  def measure(metric, fun) when is_function(fun), do: measure(%{}, metric, fun)
  def measure(metadata, metric, ms) when is_number(ms) do
    log(format_metric("measure", metric, "#{ms}ms"), metadata)
  end
  def measure(metadata, metric, fun) when is_function(fun) do

    {service_us, ret_value} = cond do
      is_function(fun, 0) -> :timer.tc(fun)
      is_function(fun, 1) -> :timer.tc(fun, [metadata])
    end

    log(format_metric("measure", metric, "#{service_us / 1000}ms"), metadata)

    ret_value
  end

  defp format_metric(type, metric, value) do
    Logfmt.encode(Map.put(%{}, prefix_metric(type, metric), value))
  end

  defp log(formatted_metric, metadata) do
    metadata_with_context =
      metadata
      |> Enum.into(%{})
      |> Map.merge(get_context())
      |> Logfmt.encode

    write("#{formatted_metric} #{metadata_with_context}")
  end

  defp prefix_metric(type, metric) do
    case Modifiers.get_prefix() do
      nil -> "#{type}##{metric}"
      _ -> "#{type}##{Modifiers.get_prefix}#{metric}"
    end
  end

  defp write(output), do: output |> Logger.info
end
