require Logger

defmodule Metrix do
  use Application
  alias Metrix.Context

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Metrix.Context, [:global])
    ]

    opts = [strategy: :one_for_one, name: Metrix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def count(metric), do: count(metric, 1)
  def count(metric, num) when is_number(num), do: count(%{}, metric, num)
  def count(metadata, metric), do: count(metadata, metric, 1)
  def count(metadata, metric, num) do
    metadata
    |> add(:"count##{metric}", num)
    |> log

    metadata
  end

  def sample(metric, value), do: sample(%{}, metric, value)
  def sample(metadata, metric, value) do
    metadata
    |> add(:"sample##{metric}", value)
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
    |> add(:"measure##{metric}", "#{service_us / 1000}ms")
    |> log

    ret_value
  end

  def log(values) do
    values
    |> Dict.merge(get_global_context)
    |> Logfmt.encode
    |> write
  end

  def set_global_context(metadata), do: Context.put(:global, metadata)
  def get_global_context, do: Context.get(:global)
  def clear_global_context, do: Context.clear(:global)

  def add_context(metadata, fun) do
    System.get_pid
    |> setup_context
    |> Context.put(metadata)

    fun.()
    System.get_pid |> Context.pop
  end

  def get_context, do: Context.get(System.get_pid)

  defp add(dict, key, value), do: dict |> Dict.put(key, value)

  defp write(output), do: output |> IO.puts

  defp setup_context(name) do
    Context.start_link(name)
    name
  end
end
