defmodule Tragedy do
  @moduledoc """
  Documentation for `Tragedy`.
  """

  @doc false
  def aggregate do
    quote do
      use Tragedy.Aggregate.Base
    end
  end

  @doc false
  def saga do
    quote do
      use Tragedy.Saga.Base
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
