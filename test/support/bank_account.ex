# SPDX-FileCopyrightText: 2021 Rosa Richter
#
# SPDX-License-Identifier: MIT

defmodule Calamity.BankAccount do
  @moduledoc false

  use Tragedy, :aggregate

  alias Calamity.Commands.{
    CreateAccount,
    RenameAccount,
    DepositFunds,
    WithdrawFunds,
    RequestTransfer,
    SendResponse
  }

  alias Calamity.Events.{
    AccountCreated,
    AccountRenamed,
    FundsWithdrawn,
    FundsDeposited,
    TransferInitiated,
    ResponsePermitted
  }

  require Logger

  defstruct account_id: nil,
            balance: 0,
            name: nil

  def new(id) do
    %__MODULE__{account_id: id}
  end

  defimpl Tragedy.Aggregate do
    def id(account) do
      account.account_id
    end

    def execute(%{account_id: account_id}, %SendResponse{
          account_id: account_id,
          response_pid: pid
        }) do
      Logger.info("Executing SendResponse")
      %ResponsePermitted{account_id: account_id, response_pid: pid}
    end

    def execute(%{account_id: account_id}, %CreateAccount{account_id: account_id}) do
      Logger.info("Executing CreateAccount")
      %AccountCreated{account_id: account_id}
    end

    def execute(account, %RenameAccount{name: name}) do
      Logger.info("Executing RenameAccount")
      %AccountRenamed{account_id: account.account_id, name: name}
    end

    def execute(account, %DepositFunds{amount: amount, transfer_id: transfer_id}) do
      Logger.info("Executing DepositFunds")

      %FundsDeposited{
        account_id: account.account_id,
        amount: amount,
        transfer_id: transfer_id
      }
    end

    def execute(account, %WithdrawFunds{amount: amount, transfer_id: transfer_id}) do
      Logger.info("Executing WithdrawFunds")

      if account.balance >= amount do
        %FundsWithdrawn{
          account_id: account.account_id,
          amount: amount,
          transfer_id: transfer_id
        }
      else
        {:error, :insufficient_funds}
      end
    end

    def execute(account, %RequestTransfer{to: to, amount: amount, transfer_id: transfer_id}) do
      Logger.info("Executing RequestTransfer")

      if account.balance >= amount do
        %TransferInitiated{
          from: account.account_id,
          to: to,
          amount: amount,
          transfer_id: transfer_id
        }
      else
        {:error, :insufficient_funds}
      end
    end

    def apply(account, %Calamity.Events.AccountCreated{}) do
      %{account | balance: 0}
    end

    def apply(account, %Calamity.Events.AccountRenamed{name: name}) do
      %{account | name: name}
    end

    def apply(account, %Calamity.Events.FundsWithdrawn{amount: amount}) do
      %{account | balance: account.balance - amount}
    end

    def apply(account, %Calamity.Events.FundsDeposited{amount: amount}) do
      %{account | balance: account.balance + amount}
    end

    def apply(account, %TransferInitiated{}) do
      account
    end

    def apply(account, %Calamity.Events.ResponsePermitted{}) do
      account
    end
  end
end
