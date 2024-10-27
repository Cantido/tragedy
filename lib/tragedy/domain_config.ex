defmodule Tragedy.DomainConfig do
  @moduledoc """
  Configuration for the Tragedy system.
  """

  @type t() :: %__MODULE__{
          saga_modules: list(module()),
          listener_specs: list(Supervisor.child_spec())
        }

  defstruct saga_modules: [],
            listener_specs: []
end
