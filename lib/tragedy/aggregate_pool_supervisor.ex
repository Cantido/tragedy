defmodule Tragedy.AggregatePoolSupervisor do
  use Supervisor

  alias Tragedy.AggregateServer

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  @impl true
  def init(_args) do
    Supervisor.init([], strategy: :one_for_one)
  end

  def start_aggregate(pool_pid, agg_mod, agg_id) do
    spec =
      {AggregateServer, [module: agg_mod, id: agg_id]}
      |> Supervisor.child_spec(id: {:aggregate, agg_mod, agg_id})

    case Supervisor.start_child(pool_pid, spec) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        {:ok, pid}

      err ->
        err
    end
  end
end
