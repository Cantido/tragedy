defmodule Tragedy.DomainSupervisor do
  use Supervisor

  alias Tragedy.AggregatePoolSupervisor
  alias Tragedy.CommandRouter
  alias Tragedy.SagaSupervisor
  alias Tragedy.ListenerSupervisor

  def start_link(config) do
    Supervisor.start_link(__MODULE__, config)
  end

  def init(config) do
    children = [
      {CommandRouter, {self(), config}} |> Supervisor.child_spec(id: :command_router),
      {AggregatePoolSupervisor, []} |> Supervisor.child_spec(id: :aggregate_pool),
      {SagaSupervisor, []} |> Supervisor.child_spec(id: :saga_supervisor),
      {ListenerSupervisor, config} |> Supervisor.child_spec(id: :listener_supervisor)
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

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

  def dispatch(supervisor, command) do
    with router_id when is_pid(router_id) <- command_router_pid(supervisor) do
      CommandRouter.dispatch(router_id, command)
    else
      _ ->
        :error
    end
  end
end
