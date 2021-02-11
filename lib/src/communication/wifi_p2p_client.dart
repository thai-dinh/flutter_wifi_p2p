import 'dart:async';
import 'dart:io';
import 'dart:typed_data';


class WifiP2pClient {
  final String _serverIp;
  final int _port;

  Socket _socket;
  StreamSubscription<Uint8List> _streamSub;

  WifiP2pClient(this._serverIp, this._port);

/*------------------------------Getters & Setters-----------------------------*/

  int get port => _port;

  Socket get socket => _socket;

  String get remoteAddress => _socket.remoteAddress.address;

/*-------------------------------Public methods-------------------------------*/

  Future<void> connect() async {
    _socket = await Socket.connect(_serverIp, _port);
  }

  Future<void> close() async {
    await _streamSub.cancel();
    _socket.destroy();
  }

  Future<void> listen(void Function(Uint8List) onData) async {
    try {
      await _listen(onData);
    } on SocketException catch (error) {
      print(error.toString());
      await close();
    }
  }

  Future<void> write(String message) async {
    try {
      _socket.write(message);
    } catch (error) {
      await close();
    }
  }

/*------------------------------Private methods-------------------------------*/

  Future<void> _listen(void Function(Uint8List) onData) async {
    _streamSub = _socket.listen(
      onData, onError: (error) => throw error, onDone: () async => await close()
    );
  }
}
