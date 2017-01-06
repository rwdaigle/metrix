defmodule Metrix.Formatter do
  @moduledoc """
  Provide formatting for metrics.
  
  This only impacts the `type#metric` portion of the output.

  The formatting can be configured with formats and parameters:

  ```
  config :metrix,
    count_format: "count#$prefix$metric",
    measure_format: "measure#$prefix$metric",
    sample_format: "sample#$prefix$metric",
    parameters: %{:prefix => "my-prefix."}
  ```

  The default formats are:

  * count: count#$metric
  * measure: measure#$metric
  * sample: sample#$metric

  Where `$metric` is the name of the metric passed in.
  """
  
  # Matches all placeholders: `$term`
  @placeholder_pattern ~r/\$(\w+)/

  def start_link() do
    Agent.start_link(fn -> init end, name: __MODULE__)
  end

  def format_count(metric) do
    format(count_format, metric)
  end

  def format_measure(metric) do
    format(measure_format, metric)
  end

  def format_sample(metric) do
    format(sample_format, metric)
  end
  
  def count_format(format_string) do
    Agent.update(__MODULE__, &Map.put(&1, :count_format, format_string))
  end
  
  def measure_format(format_string) do
    Agent.update(__MODULE__, &Map.put(&1, :measure_format, format_string))
  end
  
  def sample_format(format_string) do
    Agent.update(__MODULE__, &Map.put(&1, :sample_format, format_string))
  end

  def add_parameter(name, value) when is_atom(name), do: add_parameter(Atom.to_string(name), value)
  def add_parameter(name, value) do
    Agent.update(__MODULE__, fn(map) ->
      map
      |> Map.update!(:parameters, &Map.put(&1, name, value))
    end)
  end

  def get_parameter(name) when is_atom(name), do: get_parameter(Atom.to_string(name))
  def get_parameter(name) do
    Agent.get(__MODULE__, fn(map) ->
      map
      |> Map.get(:parameters)
      |> Map.get(name)
    end)
  end
  
  def remove_parameter(name) when is_atom(name), do: remove_parameter(Atom.to_string(name))
  def remove_parameter(name) do
    Agent.update(__MODULE__, fn(map) ->
      map
      |> Map.update!(:parameters, &Map.delete(&1, name))
    end)
  end

  def reset do
    Agent.update(__MODULE__, fn(_map) -> init end)
  end

  defp init do
    %{}
    |> capture_count_format
    |> capture_measure_format
    |> capture_sample_format
    |> capture_parameters
  end

  defp count_format do
    Agent.get(__MODULE__, &Map.get(&1, :count_format))
  end

  defp measure_format do
    Agent.get(__MODULE__, &Map.get(&1, :measure_format))
  end

  defp sample_format do
    Agent.get(__MODULE__, &Map.get(&1, :sample_format))
  end

  defp format(format_string, metric) do
    parameters
    |> Map.put("metric", metric)
    |> format_with_parameters(format_string)
    |> String.to_atom
  end

  defp format_with_parameters(parameters, format_string) do
    Regex.scan(@placeholder_pattern, format_string)
    |> Enum.reduce(format_string, fn(term, format_string) ->
      [placeholder_pattern, parameter] = term
      String.replace(format_string, placeholder_pattern, parameters[parameter])
    end)
  end

  defp parameters do
    Agent.get(__MODULE__, &Map.get(&1, :parameters))
  end

  defp capture_count_format(map) do
    map
    |> capture_format(:count_format, "count#$metric")
  end

  defp capture_measure_format(map) do
    map
    |> capture_format(:measure_format, "measure#$metric")
  end

  defp capture_sample_format(map) do
    map
    |> capture_format(:sample_format, "sample#$metric")
  end

  defp capture_format(map, atom, default) do
    map
    |> Map.merge(case Application.get_env(:metrix, atom) do
      nil -> %{atom => default}
      fmt -> %{atom => fmt}
    end)
  end

  defp capture_parameters(map) do
    Map.put(map, :parameters, capture_parameters |> normalize_parameters)
  end

  defp capture_parameters do
    case Application.get_env(:metrix, :parameters) do
      nil -> %{}
      map -> map
    end
  end

  defp normalize_parameters(parameters) do
    Enum.reduce(parameters, %{}, fn({name, value}, map) ->
      Map.put(map, normalize_term(name), normalize_term(value))
    end)
  end

  def normalize_term(term) when is_atom(term), do: Atom.to_string(term)
  def normalize_term(term), do: term
end