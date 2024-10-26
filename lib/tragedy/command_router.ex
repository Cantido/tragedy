defmodule Tragedy.CommandRouter do
  use GenServer

  alias Tragedy.ListenerSupervisor
  alias Tragedy.SagaSupervisor
  alias Tragedy.DomainSupervisor
  alias Tragedy.AggregatePoolSupervisor
  alias Tragedy.AggregateServer

  def start_link({domain_pid, config}) do
    GenServer.start_link(__MODULE__, {domain_pid, config})
  end

  def init({domain_pid, config}) do
    {:ok, %{domain_pid: domain_pid, config: config}}
  end

  @spec dispatch(GenServer.server(), Tragedy.Command.t()) :: :ok | {:error, term()}
  def dispatch(router, command) do
    GenServer.call(router, {:dispatch, command})
  end

  def handle_call({:dispatch, command}, _from, state) do
    agg_pool_pid = DomainSupervisor.aggregate_pool_supervisor_pid(state.domain_pid)

    {agg, id} = Tragedy.Command.aggregate(command)

    with {:ok, pid} when is_pid(pid) <-
           AggregatePoolSupervisor.start_aggregate(agg_pool_pid, agg, id),
         saga_sup_pid when is_pid(pid) <-
           DomainSupervisor.saga_supervisor_pid(state.domain_pid),
         listener_sup_pid when is_pid(pid) <-
           DomainSupervisor.listener_supervisor_pid(state.domain_pid) do
      result =
        do_dispatch(pid, saga_sup_pid, listener_sup_pid, state.config.saga_modules, [command])

      {:reply, result, state}
    else
      {:ok, nil} ->
        {:reply, {:error, :aggregate_failed_to_start}, state}

      err ->
        {:reply, err, state}
    end
  end

  defp do_dispatch(_, _, _, _, []) do
    :ok
  end

  defp do_dispatch(agg_pid, saga_sup_pid, listener_sup_pid, saga_modules, [
         command | remaining_commands
       ]) do
    with {:ok, events} <- AggregateServer.handle_command(agg_pid, command) do
      Enum.each(saga_modules, fn saga_mod ->
        saga_id =
          Enum.find_value(events, fn event ->
            case saga_mod.interested?(event) do
              {:start, id} -> id
              _ -> false
            end
          end)

        SagaSupervisor.start_saga(saga_sup_pid, saga_mod, saga_id)
      end)

      [
        Task.async(fn -> SagaSupervisor.handle_events(saga_sup_pid, events) end),
        Task.async(fn -> AggregateServer.handle_events(agg_pid, events) end),
        Task.async(fn -> ListenerSupervisor.handle_events(listener_sup_pid, events) end)
      ]
      |> Task.await_many()
      |> List.first()
      |> case do
        {:ok, new_commands} ->
          do_dispatch(
            agg_pid,
            saga_sup_pid,
            listener_sup_pid,
            saga_modules,
            remaining_commands ++ new_commands
          )

        err ->
          err
      end
    else
      err ->
        err
    end
  end
end
