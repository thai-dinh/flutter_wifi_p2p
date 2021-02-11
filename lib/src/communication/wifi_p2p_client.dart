import 'dart:async';
import 'dart:io';
import 'dart:typed_data';


class WifiP2pClient {
  final String _serverIp;
  final int _port;

  Socket _socket;
  StreamSubscription<Uint8List> _streamSub;

  WifiP2pClient(this._serverIp, this._port);

  int get port => _port;

  Socket get socket => _socket;

  String get remoteAddress => _socket.remoteAddress.address;

  Future<void> connect() async {
    _socket = await Socket.connect(_serverIp, _port);
  }

  Future<void> close() async {
    await _streamSub.cancel();
    _socket.destroy();
  }

  void listen(void Function(Uint8List) onData) async {
    try {
      _streamSub = _socket.listen(
        onData,
        onError: (error) async {
          print('onError: ' + error.toString());
          await close();
          return;
        },
        onDone: () async => await close()
      );
    } on SocketException catch (error) {
      print('catch: ' + error.toString());
    }
  }

  void write(String message) => _socket.write(message);
}
