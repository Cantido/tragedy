defmodule Tragedy.DomainConfig do
  @moduledoc """
  Configuration for the Tragedy system.
  """

  @type t() :: %__MODULE__{
          name: Supervisor.name(),
          saga_modules: list(module()),
          listener_specs: list(Supervisor.child_spec())
        }

  @enforce_keys [:name]
  defstruct [:name, saga_modules: [], listener_specs: []]
end
