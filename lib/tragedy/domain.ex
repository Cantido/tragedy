defmodule Tragedy.Domain do
  @doc false
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour Tragedy.Domain

      @sagas Keyword.get(opts, :sagas, [])
      @listeners Keyword.get(opts, :listeners, [])

      def child_spec(opts) do
        %{
          id: Keyword.get(opts, :name, __MODULE__),
          start: {__MODULE__, :start_link, [opts]},
          type: :supervisor
        }
      end

      def start_link(opts \\ []) do
        config = %Tragedy.DomainConfig{
          name: Keyword.get(opts, :name, __MODULE__),
          saga_modules: @sagas,
          listener_specs: @listeners
        }

        Enum.each(config.saga_modules, fn mod ->
          if Code.ensure_compiled(mod) != {:module, mod} do
            raise "Saga module #{inspect(mod)} was not found"
          end
        end)

        Enum.each(config.listener_specs, fn
          {mod, _opts} ->
            if Code.ensure_compiled(mod) != {:module, mod} do
              raise ArgumentError, "Listener module #{inspect(mod)} was not found"
            end

          mod ->
            if Code.ensure_compiled(mod) != {:module, mod} do
              raise ArgumentError, "Listener module #{inspect(mod)} was not found"
            end
        end)

        Tragedy.DomainSupervisor.start_link(config)
      end

      def dispatch(command) do
        Tragedy.DomainSupervisor.dispatch(__MODULE__, command)
      end
    end
  end

  @callback dispatch(Tragedy.Command.t()) :: :ok
end
