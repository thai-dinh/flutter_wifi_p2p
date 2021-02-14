import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_wifi_p2p/src/socket/isocket.dart';


class P2pClientSocket implements ISocket {
  final String _address;
  final int _port;

  Socket _socket;
  StreamSubscription<Uint8List> _listenStreamSub;

  P2pClientSocket(this._address, this._port);

/*------------------------------Getters & Setters-----------------------------*/

  String get address => _address;

  int get port => _port;

/*-------------------------------Public methods-------------------------------*/

  Future<void> connect(int timeout) async {
    _socket = await Socket.connect(
      _address, _port,timeout: Duration(milliseconds:  timeout)
    ).catchError((error) => throw error);
  }

  Future<void> close() async {
    if (_listenStreamSub != null)
      await _listenStreamSub.cancel();
    if (_socket != null)
      _socket.destroy();
  }

  void listen(void Function(Uint8List) onData, {void Function() onDone}) {
    _listenStreamSub = _socket.listen(
      onData, 
      onError: (error) => throw error, 
      onDone: () async => (onDone != null) ? onDone() : await close()
    );
  }

  void write(String message) {
    _socket.write(message);
    _socket.flush().catchError((error) => throw error);
  }
}
