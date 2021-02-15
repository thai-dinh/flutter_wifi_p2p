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
      _address, _port, timeout: Duration(milliseconds:  timeout)
    );
  }

  Future<void> close() async {
    if (_listenStreamSub != null)
      await _listenStreamSub.cancel();
    if (_socket != null)
      _socket.destroy();

    try {
      await _socket.done;
    } catch (error) {
      print(error.toString());
    }
  }

  void listen(
    void Function(Uint8List) onData, {void Function() onDone}
  ) async {
    _listenStreamSub = _socket.listen(onData,
      onDone: () async => (onDone != null) ? onDone() : await close()
    );

    try {
      await _socket.done;
    } catch (error) {
      print(error.toString());
    }
  }

  void write(String message) {
    _socket.write(message);
    _socket.flush();
  }
}
