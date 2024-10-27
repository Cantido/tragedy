defmodule Tragedy.SagaSupervisor do
  @moduledoc false

  use Supervisor

  alias Tragedy.SagaServer

  require Logger

  @doc false
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  @impl Supervisor
  def init(_args) do
    Supervisor.init([], strategy: :one_for_one)
  end

  def start_saga(pid, saga_module, saga_id) do
    child =
      {SagaServer, [module: saga_module, id: saga_id]}
      |> Supervisor.child_spec(id: {:saga, saga_module, saga_id})

    Supervisor.start_child(pid, child)
  end

  @doc false
  def handle_events(pid, events) do
    Enum.flat_map(events, fn event ->
      pid
      |> Supervisor.which_children()
      |> Enum.map(&event_to_child(&1, event))
      |> Task.await_many()
      |> List.flatten()
    end)
    |> then(fn commands ->
      {:ok, commands}
    end)
  end

  defp event_to_child({_, saga, _, _}, event) when is_pid(saga) do
    Task.async(fn ->
      case SagaServer.handle_event(saga, event) do
        {:ok, commands} ->
          List.wrap(commands)
      end
    end)
  end

  defp event_to_child(_, _), do: false
end
