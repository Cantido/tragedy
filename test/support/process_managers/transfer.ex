# SPDX-FileCopyrightText: 2021 Rosa Richter
#
# SPDX-License-Identifier: MIT

defmodule Calamity.ProcessManagers.Transfer do
  use Tragedy, :saga

  alias Calamity.Commands.{
    DepositFunds,
    WithdrawFunds
  }

  alias Calamity.Events.{
    TransferInitiated,
    FundsDeposited,
    FundsWithdrawn
  }

  defstruct [
    :transfer_id,
    :from,
    :to,
    :amount,
    :stage
  ]

  def interested?(%TransferInitiated{transfer_id: id}) do
    {:start, id}
  end

  def interested?(%FundsWithdrawn{transfer_id: id}) when not is_nil(id) do
    {:continue, id}
  end

  def interested?(%FundsDeposited{transfer_id: id}) when not is_nil(id) do
    {:stop, id}
  end

  def interested?(_), do: false

  def new(transfer_id) do
    %__MODULE__{transfer_id: transfer_id}
  end

  defimpl Tragedy.Saga do
    def apply(pm, %TransferInitiated{transfer_id: transfer_id, from: from, to: to, amount: amount}) do
      %Calamity.ProcessManagers.Transfer{
        pm
        | transfer_id: transfer_id,
          from: from,
          to: to,
          amount: amount,
          stage: :initiated
      }
    end

    def apply(
          %Calamity.ProcessManagers.Transfer{from: from, amount: amount, stage: :initiated} = pm,
          %FundsWithdrawn{account_id: from, amount: amount}
        ) do
      %Calamity.ProcessManagers.Transfer{
        pm
        | stage: :funds_withdrawn
      }
    end

    def apply(
          %Calamity.ProcessManagers.Transfer{from: from, amount: amount, stage: :funds_withdrawn} =
            pm,
          %FundsDeposited{account_id: from, amount: amount}
        ) do
      %Calamity.ProcessManagers.Transfer{
        pm
        | stage: :complete
      }
    end

    def handle(pm, %TransferInitiated{}) do
      %WithdrawFunds{
        account_id: pm.from,
        transfer_id: pm.transfer_id,
        amount: pm.amount
      }
    end

    def handle(pm, %FundsWithdrawn{}) do
      %DepositFunds{
        account_id: pm.to,
        transfer_id: pm.transfer_id,
        amount: pm.amount
      }
    end

    def handle(_pm, %FundsDeposited{}) do
      nil
    end
  end
end
