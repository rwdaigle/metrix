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


  @doc """
  Adds `metadata` to the global context, which will add the metadata values
  to all subsequent metrix output. Global context is useful for component-wide
  values, such as source=X or app=Y metadata, that remains unchanged throughout
  the life of your application.
  """
  def add_context(metadata), do: Context.put(metadata)
  def get_context, do: Context.get
  def clear_context, do: Context.clear

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
    |> Dict.merge(get_context)
    |> Logfmt.encode
    |> write
  end

  defp add(dict, key, value), do: dict |> Dict.put(key, value)

  defp write(output), do: output |> Logger.info
end
