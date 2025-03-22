defmodule TragedyTest do
  use ExUnit.Case

  alias Tragedy.DomainConfig
  alias Tragedy.DomainSupervisor

  doctest Tragedy

  test "listeners get events" do
    pid =
      start_supervised!(
        {DomainSupervisor,
         %DomainConfig{
           name: :listener_test,
           listener_specs: [{Calamity.MessengerListener, pid: self()}]
         }}
      )

    :ok = DomainSupervisor.dispatch(pid, %Calamity.Commands.CreateAccount{account_id: "test id"})

    assert_receive {:listener_received_event, event}

    assert event == %Calamity.Events.AccountCreated{account_id: "test id"}
  end

  test "aggregate errors bubble up to caller" do
    pid =
      start_supervised!(
        {DomainSupervisor,
         %DomainConfig{
           name: :aggregate_error_test,
           saga_modules: [Calamity.ProcessManagers.Transfer],
           listener_specs: [{Calamity.MessengerListener, pid: self()}]
         }}
      )

    :ok = DomainSupervisor.dispatch(pid, %Calamity.Commands.CreateAccount{account_id: "1"})
    :ok = DomainSupervisor.dispatch(pid, %Calamity.Commands.CreateAccount{account_id: "2"})

    assert {:error, :insufficient_funds} ==
             DomainSupervisor.dispatch(pid, %Calamity.Commands.RequestTransfer{
               from: "1",
               to: "2",
               transfer_id: "test transfer",
               amount: 100
             })
  end

  test "sagas get run" do
    pid =
      start_supervised!(
        {DomainSupervisor,
         %DomainConfig{
           name: :saga_test,
           saga_modules: [Calamity.ProcessManagers.Transfer],
           listener_specs: [{Calamity.MessengerListener, pid: self()}]
         }}
      )

    :ok = DomainSupervisor.dispatch(pid, %Calamity.Commands.CreateAccount{account_id: "1"})
    :ok = DomainSupervisor.dispatch(pid, %Calamity.Commands.CreateAccount{account_id: "2"})

    :ok =
      DomainSupervisor.dispatch(pid, %Calamity.Commands.DepositFunds{account_id: "1", amount: 100})

    :ok =
      DomainSupervisor.dispatch(pid, %Calamity.Commands.RequestTransfer{
        from: "1",
        to: "2",
        transfer_id: "test transfer",
        amount: 100
      })

    assert_receive {:listener_received_event,
                    %Calamity.Events.FundsDeposited{transfer_id: "test transfer"}}
  end

  test "use domain listeners get called" do
    start_supervised!(Calamity.Domain)

    :ok =
      Calamity.Domain.dispatch(%Calamity.Commands.SendResponse{
        account_id: "test id",
        response_pid: self()
      })

    assert_receive {:listener_received_event, event}

    assert event.account_id == "test id"
  end
end
