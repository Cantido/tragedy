# SPDX-FileCopyrightText: 2021 Rosa Richter
#
# SPDX-License-Identifier: MIT

defmodule Calamity.Commands.RenameAccount do
  @moduledoc false

  defstruct [
    :account_id,
    :name
  ]

  defimpl Tragedy.Command do
    def aggregate(command) do
      {Calamity.BankAccount, command.account_id}
    end
  end
end
