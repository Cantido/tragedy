defprotocol Tragedy.Saga do
  @moduledoc """
  Coordinates aggregates by emitting commands based on events.
  """

  @doc """
  Update the saga's state based on the event.
  """
  @spec apply(t(), any()) :: t()
  def apply(saga, event)

  @doc """
  Emits commands in response to events.
  """
  @spec handle(t(), any()) :: any() | list(any())
  def handle(saga, event)
end
