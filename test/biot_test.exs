defmodule Biot.Test do
  use ExUnit.Case

  defp now_utc, do: DateTime.utc_now() |> DateTime.to_unix(:millisecond)

  test "simple protocol flow" do
    vdevice_id = 8

    task =
      Task.async(fn ->
        {:ok, socket} =
          :gen_tcp.connect({127, 0, 0, 1}, 4040, [:binary, packet: 1, active: false])

        :gen_tcp.send(
          socket,
          <<1::integer-size(8), vdevice_id::integer-size(16), 2::integer-size(16)>>
        )

        {:ok, <<2::integer-size(8)>>} = :gen_tcp.recv(socket, 0)

        payload_1 = <<now_utc()::integer-size(64), 1::integer-size(16)>>

        :gen_tcp.send(
          socket,
          <<3::integer-size(8)>> <> payload_1
        )

        {:ok, <<4::integer-size(8)>>} = :gen_tcp.recv(socket, 0)

        payload_2 = <<now_utc()::integer-size(64), 2::integer-size(16)>>

        :gen_tcp.send(
          socket,
          <<3::integer-size(8)>> <> payload_1
        )

        {:ok, <<4::integer-size(8)>>} = :gen_tcp.recv(socket, 0)

        :gen_tcp.send(socket, <<5::integer-size(8)>>)
        {:ok, [payload_1, payload_2]}
      end)

    {:ok, [datum_1_expected, datum_2_expected]} = Task.await(task)

    :timer.sleep(100)

    {:ok, vdevice} = Biot.VDeviceFactory.start_or_get(vdevice_id)

    datum_1_actual = Biot.VDevice.pop(vdevice)
    datum_2_actual = Biot.VDevice.pop(vdevice)

    assert datum_1_actual = datum_1_expected
    assert datum_2_actual = datum_2_expected
  end
end
