defmodule Tragedy.Aggregate.Base do
  @moduledoc """
  The base module for any aggregate.
  Tragedy needs a factory function to build new aggregates when one does not exist.
  This module provides a behaviour to make sure it will work as expected when you hand it to `Tragedy`.

  Do not use this module directly, import it with `use Tragedy, :aggregate`.
  """

  @doc """
  Build a new aggregate struct.

  This function will be called with the ID result of `Tragedy.Command.aggregate/1`.
  """
  @callback new(any()) :: Tragedy.Aggregate.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour Tragedy.Aggregate.Base
      @after_compile __MODULE__

      defmacro __after_compile__(_env, _bytecode) do
        Protocol.assert_impl!(Tragedy.Aggregate, __MODULE__)
      end
    end
  end
end
