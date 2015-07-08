defmodule Metrix.Context do

  @timeout_ms 5

  @doc """
  Starts a new context.
  """
  def start_link(name) do
    Agent.start_link(fn -> [] end, name: name)
  end

  @doc """
  Gets current context, flattened
  """
  def get(name) do
    IO.puts "Getting context from #{name}"
    # collapse =
    # &Enum.reduce(&1, %{}, fn(next, all) -> Dict.merge(all, next) end)
    Agent.get(name, fn ctx -> ctx end, @timeout_ms)
  end

  @doc """
  Adds the `metadata` to the context
  """
  def put(name, metadata) do
    IO.puts "Adding context to #{name}"
    Agent.update(name, fn curr_md -> [metadata|curr_md] end, @timeout_ms)
  end

  @doc """
  Removes the last metadata
  """
  def pop(name) do
    pop_fun = fn
      [_|rest] -> rest
      [] -> []
    end
    Agent.update(name, &pop_fun.(&1), @timeout_ms)
  end

  @doc """
  Clears the existing context
  """
  def clear(name) do
    Agent.update(name, fn _ -> [] end, @timeout_ms)
  end

  @doc """
  Stop the given agent
  """
  def stop(name) do
    Agent.stop(name, @timeout_ms)
  end
end
