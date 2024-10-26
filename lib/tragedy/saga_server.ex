defmodule Tragedy.SagaServer do
  @moduledoc false

  use GenServer

  alias Tragedy.Saga

  require Logger

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl GenServer
  def init(args) do
    module = Keyword.fetch!(args, :module)
    id = Keyword.fetch!(args, :id)
    {:ok, %{module: module, id: id, saga: module.new(id)}}
  end

  @doc false
  @spec handle_event(GenServer.server(), term()) :: {:ok, list(Tragedy.Command.t())}
  def handle_event(pid, event) do
    GenServer.call(pid, {:handle_event, event})
  end

  @impl GenServer
  def handle_call({:handle_event, event}, _from, state) do
    case state.module.interested?(event) do
      {:start, id} when id == state.id ->
        saga = Saga.apply(state.saga, event)
        commands = Saga.handle(saga, event)

        {:reply, {:ok, commands}, %{state | saga: saga}}

      {:continue, id} when id == state.id ->
        saga = Saga.apply(state.saga, event)
        commands = Saga.handle(saga, event)

        {:reply, {:ok, commands}, %{state | saga: saga}}

      {:stop, id} when id == state.id ->
        saga = Saga.apply(state.saga, event)
        commands = Saga.handle(saga, event)

        {:stop, :normal, {:ok, commands}, %{state | saga: saga}}

      _ ->
        {:reply, {:ok, []}, state}
    end
  end
end
