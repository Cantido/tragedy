defmodule Tragedy.Saga.Base do
  @moduledoc """
  Base module for Tragedy's sagas.

  Tragedy needs to know if a saga should be called for a given event,
  and which saga to call.
  """

  @doc """
  Control whether a saga should be called for this event.
  """
  @callback interested?(any()) :: {:start, any()} | {:continue, any()} | {:stop, any()}

  @doc """
  Create a new saga with the given ID.
  """
  @callback new(any()) :: Tragedy.Saga.t()

  @doc false
  def handle_event(mod, sagas, event) do
    {interest, id} = mod.interested?(event)

    sagas =
      case interest do
        :start -> Map.put_new_lazy(sagas, id, fn -> mod.new(id) end)
        :continue -> sagas
        :stop -> Map.delete(sagas, id)
      end

    Access.get_and_update(sagas, id, fn
      nil ->
        :pop

      saga ->
        saga = Tragedy.Saga.apply(saga, event)
        commands = Tragedy.Saga.handle(saga, event)
        {commands, saga}
    end)
  end

  defmacro __using__(_opts) do
    quote do
      @behaviour Tragedy.Saga.Base
      @after_compile __MODULE__

      defmacro __after_compile__(_env, _bytecode) do
        Protocol.assert_impl!(Tragedy.Saga, __MODULE__)
      end
    end
  end
end
