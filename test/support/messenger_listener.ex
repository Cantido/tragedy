defmodule Calamity.MessengerListener do
  alias Calamity.Events.ResponsePermitted
  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts)
  def init(opts), do: {:ok, opts}

  def handle_call({:event, event}, _from, opts) do
    case event do
      %ResponsePermitted{response_pid: pid} ->
        send(pid, {:listener_received_event, event})

      _ ->
        Keyword.fetch!(opts, :pid)
        |> send({:listener_received_event, event})
    end

    {:reply, :ok, opts}
  end
end
