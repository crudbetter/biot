defmodule Biot.VDeviceFactory do
  use DynamicSupervisor

  alias __MODULE__, as: Mod

  def start_link(arg) do
    DynamicSupervisor.start_link(Mod, arg, name: Mod)
  end

  def start_child(vdevice_id) do
    DynamicSupervisor.start_child(Mod, {Biot.VDevice, vdevice_id})
  end

  def start_or_get(vdevice_id) do
    case Biot.VDevice.lookup(vdevice_id) do
      [{vdevice, _}] -> {:ok, vdevice}
      [] -> start_child(vdevice_id)
    end
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
