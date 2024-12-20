# SPDX-FileCopyrightText: 2021 Rosa Richter
#
# SPDX-License-Identifier: MIT

defmodule Calamity.Events.FundsWithdrawn do
  @moduledoc false

  defstruct [
    :account_id,
    :transfer_id,
    :amount
  ]
end
