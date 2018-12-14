defmodule Biot.VDevice do
  use GenServer

  alias __MODULE__, as: Mod

  def lookup(vdevice_id) do
    Registry.lookup(Registry.Via, {Mod, vdevice_id})
  end

  def start_link(vdevice_id) do
    GenServer.start_link(Mod, [], name: {:via, Registry, {Registry.Via, {Mod, vdevice_id}}})
  end

  def push(vdevice, head) do
    GenServer.cast(vdevice, {:push, head})
  end

  def pop(vdevice) do
    GenServer.call(vdevice, :pop)
  end

  ## Callbacks

  def init(stack) do
    {:ok, stack}
  end

  def handle_call(:pop, _from, [head | tail]) do
    {:reply, head, tail}
  end

  def handle_cast({:push, head}, tail) do
    {:noreply, [head | tail]}
  end
end
