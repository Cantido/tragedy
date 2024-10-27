defmodule Tragedy.ListenerSupervisor do
  @moduledoc false

  use Supervisor

  @doc false
  @spec start_link(Tragedy.DomainConfig.t()) :: Supervisor.on_start()
  def start_link(config) do
    Supervisor.start_link(__MODULE__, config)
  end

  @impl Supervisor
  def init(%Tragedy.DomainConfig{} = config) do
    Supervisor.init(config.listener_specs, strategy: :one_for_one)
  end

  @doc false
  @spec handle_events(Supervisor.supervisor(), list(any())) :: :ok
  def handle_events(pid, events) do
    pid
    |> Supervisor.which_children()
    |> Enum.map(&events_to_child(&1, events))
    |> Task.await_many()

    :ok
  end

  defp events_to_child({_, listener, _, _}, events) when is_pid(listener) do
    Task.async(fn ->
      Enum.map(events, fn event ->
        GenServer.call(listener, {:event, event})
      end)
    end)
  end

  defp events_to_child(_, _), do: false
end
