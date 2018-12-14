defmodule Biot do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Supervisor.child_spec({Biot.Gateway, 4040}, restart: :permanent),
      {Task.Supervisor, name: Biot.ConnectionHandlers},
      {DynamicSupervisor, strategy: :one_for_one, name: Biot.ProtocolHandlers},
      Biot.VDeviceFactory,
      {Registry, keys: :unique, name: Registry.Via}
    ]

    opts = [strategy: :one_for_one, name: Biot.GateKeeper]

    Supervisor.start_link(children, opts)
  end
end
