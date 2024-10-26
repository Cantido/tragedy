defprotocol Tragedy.Aggregate do
  @moduledoc """
  The core business logic of part of a domain.

  An aggregate is usually some grouping of domain objects that maintains a transactional boundary.
  That means that the group of objects must be updated together in order for data to remain consistent.

  Aggregates are the first piece of your domain that touches a command.
  They can either reject the command or issue events.
  If they issue events, those events are then used to update the state of the aggregate.
  """

  @doc """
  Returns the unique ID of an aggregate.
  """
  @spec id(t()) :: any()
  def id(agg)

  @doc """
  Update the aggregate's state based on an event.
  """
  @spec apply(t(), any()) :: t()
  def apply(agg, event)

  @doc """
  Transform a command into one or more events.
  """
  @spec execute(t(), Tragedy.Command.t()) :: any() | list(any()) | {:ok, any()} | {:ok, list(any())} | {:error, any()}
  def execute(agg, command)
end
