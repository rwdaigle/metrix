defmodule Metrix.Modifiers do
  @moduledoc """
  This could hold any modifiers. Perhaps a more generic approach would
  be to allow the configuration of each metric format.

  This could be merged into the Metrix.Context by giving the context a
  namespace within the map.
  """
  
  @doc """
  Starts the agent.
  """
  def start_link(initial_modifiers) do
    Agent.start_link(fn -> initial_modifiers end, name: __MODULE__)
  end

  @doc """
  Get the metric prefix.
  """
  def get_prefix do
    Agent.get(__MODULE__, &Map.get(&1, :prefix))
  end

  @doc """
  Sets the metric prefix
  """
  def put_prefix(prefix) do
    Agent.update(__MODULE__, &Map.put(&1, :prefix, prefix))
  end

  @doc """
  Clear the metric prefix
  """
  def clear_prefix do
    Agent.update(__MODULE__, &Map.delete(&1, :prefix))
  end

end