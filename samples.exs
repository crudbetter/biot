now_utc = fn -> DateTime.utc_now |> DateTime.to_unix(:millisecond) end


{:ok, socket} = :gen_tcp.connect({127, 0, 0, 1}, 4040, [:binary, active: false])

:gen_tcp.send(socket, <<1::integer-size(8), 8::integer-size(16), 2::integer-size(16)>>)

{:ok, <<2::integer-size(8)>>} = :gen_tcp.recv(socket, 0)

:gen_tcp.send(
  socket,
  <<3::integer-size(8), now_utc.()::integer-size(64), 1::integer-size(16)>>
)

{:ok, <<4::integer-size(8)>>} = :gen_tcp.recv(socket, 0)

:gen_tcp.send(
  socket,
  <<3::integer-size(8), now_utc.()::integer-size(64), 2::integer-size(16)>>
)

:gen_tcp.send(socket, <<5::integer-size(8)>>)
:ok