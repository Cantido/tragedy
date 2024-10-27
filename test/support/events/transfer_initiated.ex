# SPDX-FileCopyrightText: 2021 Rosa Richter
#
# SPDX-License-Identifier: MIT

defmodule Calamity.Events.TransferInitiated do
  @moduledoc false

  defstruct [
    :transfer_id,
    :from,
    :to,
    :amount
  ]
end
