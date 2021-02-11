import 'dart:io';
import 'dart:typed_data';


class WifiP2pClient {
  final String _serverIp;
  final int _port;

  Socket _socket;

  WifiP2pClient(this._serverIp, this._port);

  int get port => _port;

  String get remoteAddress => _socket.remoteAddress.address;

  Future<void> connect() async {
    _socket = await Socket.connect(_serverIp, _port);
  }

  Future<void> close() async => await _socket.close();

  void listen(void Function(Uint8List) onData) => _socket.listen(onData);

  void write(String message) => _socket.write(message);
}
