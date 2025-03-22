defmodule Calamity.Commands.SendResponse do
  @moduledoc false

  @derive {Tragedy.Command, mod: Calamity.BankAccount, key: :account_id}
  defstruct [
    :account_id,
    :response_pid
  ]
end
