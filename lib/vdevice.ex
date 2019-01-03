defmodule Biot.VDevice do
  use GenServer

  alias __MODULE__, as: Mod

  def lookup(vdevice_id) do
    Registry.lookup(Registry.Via, {Mod, vdevice_id})
  end

  def start_link(vdevice_id) do
    GenServer.start_link(Mod, {vdevice_id, []},
      name: {:via, Registry, {Registry.Via, {Mod, vdevice_id}}}
    )
  end

  def push(vdevice, head) do
    GenServer.cast(vdevice, {:push, head})
  end

  ## Callbacks

  def init({vdevice_id, buffer}) do
    Process.send_after(self(), :flush, 10_000)

    {:ok, %{vdevice_id: vdevice_id, buffer: buffer}}
  end

  def handle_info(:flush, state) do
    URI.encode("http://127.0.0.1:8086/write?db=biot&precision=ms")
    |> HTTPotion.post(body: construct_line_protocol(state))

    Process.send_after(self(), :flush, 10_000)

    {:noreply, %{state | buffer: []}}
  end

  def handle_cast({:push, head}, state = %{buffer: tail}) do
    {:noreply, %{state | buffer: [head | tail]}}
  end

  defp construct_line_protocol(%{vdevice_id: vdevice_id, buffer: buffer}) do
    Enum.reduce(buffer, "", fn [ts, v], acc ->
      acc <>
        ~s(signal_raw,vdevice_id=#{vdevice_id} sample=#{v} #{ts}\n) <>
        ~s(signal_cal,vdevice_id=#{vdevice_id} sample=#{:math.sin(v)} #{ts}\n)
    end)
  end
end
