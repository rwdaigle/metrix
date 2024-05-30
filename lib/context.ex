defmodule Metrix.Context do

  use Agent

  @doc """
  Starts a new context.
  """
  def start_link(initial_context) when is_list(initial_context) do
    Enum.into(initial_context, %{}) |> start_link
  end
  def start_link(initial_context) when is_map(initial_context) do
    Agent.start_link(fn -> initial_context end, name: __MODULE__)
  end

  @doc """
  Gets current context
  """
  def get do
    Agent.get(__MODULE__, &(&1))
  end

  @doc """
  Adds the `metadata` to the context
  """
  def put(metadata) when is_list(metadata), do: Enum.into(metadata, %{}) |> put
  def put(metadata) when is_map(metadata) do
    Agent.update(__MODULE__, &Map.merge(&1, metadata))
  end

  @doc """
  Clears the existing context
  """
  def clear do
    Agent.update(__MODULE__, fn _metadata -> %{} end)
  end
end
