defmodule Tragedy.ListenerSupervisor do
  use Supervisor

  def start_link(config) do
    Supervisor.start_link(__MODULE__, config)
  end

  @impl true
  def init(%Tragedy.DomainConfig{} = config) do
    Supervisor.init(config.listener_modules, strategy: :one_for_one)
  end

  def handle_events(pid, events) do
    pid
    |> Supervisor.which_children()
    |> Enum.map(fn {_mod, listener, _, _} ->
      Task.async(fn ->
        Enum.map(events, fn event ->
          GenServer.call(listener, {:event, event})
        end)
      end)
    end)
    |> Task.await_many()

    :ok
  end
end
