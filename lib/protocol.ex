defmodule Biot.ProtocolHandler do
  @moduledoc false

  use GenStateMachine

  alias __MODULE__, as: Mod

  require Logger

  def start_link(acceptSocket) do
    GenStateMachine.start_link(Mod, acceptSocket,
      name: {:via, Registry, {Registry.Via, {Mod, acceptSocket}}}
    )
  end

  def handle(handler, data) do
    GenStateMachine.call(handler, data)
  end

  ## Callbacks

  def init(acceptSocket) do
    {:ok, :ready, %{acceptSocket: acceptSocket, how_many: nil, vdevice: nil}}
  end

  def handle_event(
        {:call, from},
        <<1::integer-size(8), vdevice_id::integer-size(16), how_many::integer-size(16)>>,
        :ready,
        data
      ) do
    {:ok, vdevice} = Biot.VDeviceFactory.start_or_get(vdevice_id)

    updated_data = %{data | how_many: how_many, vdevice: vdevice}

    {:next_state, :connected, updated_data, [{:reply, from, <<2::integer-size(8)>>}]}
  end

  def handle_event(
        {:call, from},
        <<5::integer-size(8)>>,
        :connected,
        data = %{how_many: 0}
      ) do
    {:stop_and_reply, :shutdown, [{:reply, from, :disconnect}]}
  end

  def handle_event(
        {:call, from},
        <<3::integer-size(8), timestamp::integer-size(64), value::integer-size(64)>>,
        :connected,
        data = %{how_many: how_many, vdevice: vdevice}
      ) do
    :ok = Biot.VDevice.push(vdevice, [timestamp, value])
    updated_data = %{data | how_many: how_many - 1}
    {:next_state, :connected, updated_data, [{:reply, from, <<4::integer-size(8)>>}]}
  end
end
