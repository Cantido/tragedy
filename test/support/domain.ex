defmodule Calamity.Domain do
  use Tragedy.Domain,
    sagas: [Calamity.ProcessManagers.Transfer],
    listeners: [Calamity.MessengerListener]
end
