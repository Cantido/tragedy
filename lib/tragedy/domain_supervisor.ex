defmodule Tragedy.DomainSupervisor do
  @moduledoc false

  use Supervisor

  alias Tragedy.AggregatePoolSupervisor
  alias Tragedy.CommandRouter
  alias Tragedy.SagaSupervisor
  alias Tragedy.ListenerSupervisor

  @spec start_link(Tragedy.DomainConfig.t()) :: Supervisor.on_start()
  def start_link(config) do
    Supervisor.start_link(__MODULE__, config)
  end

  @impl Supervisor
  def init(config) do
    children = [
      {CommandRouter, {self(), config}} |> Supervisor.child_spec(id: :command_router),
      {AggregatePoolSupervisor, []} |> Supervisor.child_spec(id: :aggregate_pool),
      {SagaSupervisor, []} |> Supervisor.child_spec(id: :saga_supervisor),
      {ListenerSupervisor, config} |> Supervisor.child_spec(id: :listener_supervisor)
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc false
  @spec command_router_pid(Supervisor.supervisor()) :: pid() | nil
  def command_router_pid(supervisor) do
    supervisor
    |> Supervisor.which_children()
    |> Enum.find_value(fn
      {:command_router, router_pid, _, _} when is_pid(router_pid) ->
        router_pid

      _ ->
        false
    end)
  end

  @doc false
  @spec aggregate_pool_supervisor_pid(Supervisor.supervisor()) :: pid() | nil
  def aggregate_pool_supervisor_pid(supervisor) do
    supervisor
    |> Supervisor.which_children()
    |> Enum.find_value(fn
      {:aggregate_pool, agg_pool_sup_pid, _, _} when is_pid(agg_pool_sup_pid) ->
        agg_pool_sup_pid

      _ ->
        false
    end)
  end

  @doc false
  @spec saga_supervisor_pid(Supervisor.supervisor()) :: pid() | nil
  def saga_supervisor_pid(supervisor) do
    supervisor
    |> Supervisor.which_children()
    |> Enum.find_value(fn
      {:saga_supervisor, pid, _, _} when is_pid(pid) ->
        pid

      _ ->
        false
    end)
  end

  @doc false
  @spec listener_supervisor_pid(Supervisor.supervisor()) :: pid() | nil
  def listener_supervisor_pid(supervisor) do
    supervisor
    |> Supervisor.which_children()
    |> Enum.find_value(fn
      {:listener_supervisor, pid, _, _} when is_pid(pid) ->
        pid

      _ ->
        false
    end)
  end

  @doc false
  @spec dispatch(Supervisor.supervisor(), Tragedy.Command.t()) :: :ok | :error | {:error, any()}
  def dispatch(supervisor, command) do
    with router_id when is_pid(router_id) <- command_router_pid(supervisor) do
      CommandRouter.dispatch(router_id, command)
    else
      _ ->
        :error
    end
  end
end
