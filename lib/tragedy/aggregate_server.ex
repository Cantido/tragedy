defmodule Tragedy.AggregateServer do
  alias Calamity.Aggregate
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    agg_mod = Keyword.fetch!(args, :module)
    agg_id = Keyword.fetch!(args, :id)

    agg_state = agg_mod.new(agg_id)

    {:ok, %{module: agg_mod, id: agg_id, aggregate: agg_state}}
  end

  @spec handle_command(GenServer.server(), Calamity.Command.t()) :: {:ok, list(term())} | {:error, term()}
  def handle_command(agg_pid, command) do
    GenServer.call(agg_pid, {:handle_command, command})
  end

  def handle_events(agg_pid, events) do
    GenServer.call(agg_pid, {:handle_events, events})
  end

  def handle_call({:handle_command, command}, _from, state) do
    case Aggregate.execute(state.aggregate, command) do
      {:error, err} ->
        {:reply, {:error, err}, state}

      {:ok, events} ->
        {:reply, {:ok, events}, state}

      events ->
        {:reply, {:ok, List.wrap(events)}, state}
    end
  end

  def handle_call({:handle_events, events}, _from, state) do
    aggregate =
      Enum.reduce(events, state.aggregate, fn event, aggregate ->
        Aggregate.apply(aggregate, event)
      end)

    {:reply, :ok, %{state | aggregate: aggregate}}
  end
end
