defmodule Biot.Gateway do
  @moduledoc false

  use GenServer

  require Logger

  def start_link(port) do
    GenServer.start_link(__MODULE__, port, name: __MODULE__)
  end

  def init(port) do
    {:ok, listenSocket} =
      :gen_tcp.listen(port, [:binary, packet: 1, active: false, reuseaddr: true])

    Logger.info("Accepting connections on port #{port}")
    send(self(), :loop_acceptor)
    {:ok, %{listenSocket: listenSocket}}
  end

  def handle_info(:loop_acceptor, state = %{listenSocket: listenSocket}) do
    {:ok, acceptSocket} = :gen_tcp.accept(listenSocket)

    {:ok, pid} =
      Task.Supervisor.start_child(Biot.ConnectionHandlers, fn ->
        spec = %{
          id: Biot.ProtocolHandler,
          start: {Biot.ProtocolHandler, :start_link, [acceptSocket]},
          restart: :temporary
        }

        {:ok, handler} = DynamicSupervisor.start_child(Biot.ProtocolHandlers, spec)

        serve(acceptSocket, handler)
      end)

    :ok = :gen_tcp.controlling_process(acceptSocket, pid)
    :loop_acceptor = send(self(), :loop_acceptor)
    {:noreply, state}
  end

  defp serve(acceptSocket, handler) do
    msg =
      with {:ok, data} <- :gen_tcp.recv(acceptSocket, 0),
           do: Biot.ProtocolHandler.handle(handler, data)

    write_line(acceptSocket, msg)
    serve(acceptSocket, handler)
  end

  defp write_line(_, :disconnect), do: exit(:shutdown)
  defp write_line(_, {:error, :closed}), do: exit(:shutdown)

  defp write_line(acceptSocket, {:error, reason}),
    do: :gen_tcp.send(acceptSocket, Atom.to_string(reason))

  defp write_line(acceptSocket, msg),
    do: :gen_tcp.send(acceptSocket, msg)
end
