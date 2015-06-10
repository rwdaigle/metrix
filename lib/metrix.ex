require Logger

defmodule Metrix do
  use Application
  alias Metrix.Context

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Metrix.Context, [])
    ]

    opts = [strategy: :one_for_one, name: Metrix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def add_context(metadata), do: Context.put(metadata)
  def get_context, do: Context.get
  def clear_context, do: Context.clear

  def count(metric), do: count(metric, 1)
  def count(metadata, metric) when is_map(metadata), do: count(metadata, metric, 1)
  def count(metric, num), do: count(%{}, metric, num)
  def count(metadata, metric, num) do
    metadata
    |> Map.put("count##{metric}", num)
    |> log

    metadata
  end

  def sample(metric, value), do: sample(%{}, metric, value)
  def sample(metadata, metric, value) do
    metadata
    |> Map.put("sample##{metric}", value)
    |> log

    metadata
  end

  def measure(metric, fun), do: measure(%{}, metric, fun)
  def measure(metadata, metric, fun) do

    {service_us, ret_value} = cond do
      is_function(fun, 0) -> :timer.tc(fun)
      is_function(fun, 1) -> :timer.tc(fun, [metadata])
    end

    metadata
    |> Map.put("measure##{metric}", "#{service_us / 1000}ms")
    |> log

    ret_value
  end

  def log(map) when is_map(map) do
    map
    |> Map.merge(get_context)
    |> Logfmt.encode
    |> write
  end

  defp write(output), do: output |> IO.puts
end
