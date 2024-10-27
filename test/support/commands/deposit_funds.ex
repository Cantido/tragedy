# SPDX-FileCopyrightText: 2021 Rosa Richter
#
# SPDX-License-Identifier: MIT

defmodule Calamity.Commands.DepositFunds do
  @moduledoc false

  defstruct [
    :account_id,
    :transfer_id,
    :amount
  ]

  defimpl Tragedy.Command do
    def aggregate(%{account_id: id}) do
      {Calamity.BankAccount, id}
    end
  end
end
