defmodule Metrix.Context do
  @doc """
  Starts a new context.
  """
  def start_link do
    Agent.start_link(fn -> config() end, name: __MODULE__)
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
  def put(metadata) do
    Agent.update(__MODULE__, &Dict.merge(&1, metadata))
  end

  @doc """
  Clears the existing context
  """
  def clear do
    Agent.update(__MODULE__, fn _metadata -> %{} end)
  end

  # Read any configuration values
  defp config do
    case Application.get_env(:metrix, :context) do
      nil -> %{}
      context ->
        context
    end
  end
end
