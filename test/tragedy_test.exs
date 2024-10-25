defmodule TragedyTest do
  use ExUnit.Case

  alias Tragedy.DomainConfig
  alias Tragedy.DomainSupervisor

  doctest Tragedy

  defmodule TestListener do
    use GenServer

    def start_link(test_pid), do: GenServer.start_link(__MODULE__, test_pid)
    def init(test_pid), do: {:ok, test_pid}

    def handle_call({:event, event}, _from, test_pid) do
      send(test_pid, {:event, event})
      {:reply, :ok, test_pid}
    end
  end

  test "listeners get events" do
    pid =
      start_supervised!(
        {DomainSupervisor, %DomainConfig{listener_specs: [{TestListener, self()}]}}
      )

    :ok = DomainSupervisor.dispatch(pid, %Calamity.Commands.CreateAccount{account_id: "test id"})

    assert_receive {:event, event}

    assert event == %Calamity.Events.AccountCreated{account_id: "test id"}
  end

  test "aggregate errors bubble up to caller" do
    pid =
      start_supervised!(
        {DomainSupervisor,
         %DomainConfig{
           saga_modules: [Calamity.ProcessManagers.Transfer],
           listener_specs: [{TestListener, self()}]
         }}
      )

    :ok = DomainSupervisor.dispatch(pid, %Calamity.Commands.CreateAccount{account_id: "1"})
    :ok = DomainSupervisor.dispatch(pid, %Calamity.Commands.CreateAccount{account_id: "2"})
    assert {:error, :insufficient_funds} == DomainSupervisor.dispatch(pid, %Calamity.Commands.RequestTransfer{from: "1", to: "2", transfer_id: "test transfer", amount: 100})
  end

  test "sagas get run" do
    pid =
      start_supervised!(
        {DomainSupervisor,
         %DomainConfig{
           saga_modules: [Calamity.ProcessManagers.Transfer],
           listener_specs: [{TestListener, self()}]
         }}
      )

    :ok = DomainSupervisor.dispatch(pid, %Calamity.Commands.CreateAccount{account_id: "1"})
    :ok = DomainSupervisor.dispatch(pid, %Calamity.Commands.CreateAccount{account_id: "2"})
    :ok = DomainSupervisor.dispatch(pid, %Calamity.Commands.DepositFunds{account_id: "1", amount: 100})
    :ok = DomainSupervisor.dispatch(pid, %Calamity.Commands.RequestTransfer{from: "1", to: "2", transfer_id: "test transfer", amount: 100})

    assert_receive {:event, %Calamity.Events.FundsDeposited{transfer_id: "test transfer"}}
  end
end
