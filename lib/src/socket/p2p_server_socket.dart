import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_wifi_p2p/src/socket/isocket.dart';


class P2pServerSocket implements ISocket {
  final String _address;
  final int _port;

  ServerSocket _serverSocket;
  StreamSubscription<Socket> _listenStreamSub;
  HashMap<String, StreamSubscription<Uint8List>> _mapIpStream;
  HashMap<String, Socket> _mapIpSocket;

  P2pServerSocket(this._address, this._port) {
    _mapIpStream = HashMap();
    _mapIpSocket = HashMap();
  }

/*------------------------------Getters & Setters-----------------------------*/

  String get address => _address;

  int get port => _port;

/*-------------------------------Public methods-------------------------------*/

  Future<void> openServer() async {
    _serverSocket = await ServerSocket.bind(_address, _port, shared: true)
      .catchError((error) => throw error);
  }

  void listen(void Function(Uint8List) onData) {
    _listenStreamSub = _serverSocket.listen(
      (socket) {
        String remoteAddress = socket.remoteAddress.address;
        _mapIpSocket.putIfAbsent(remoteAddress, () => socket);
        _mapIpStream.putIfAbsent(remoteAddress, () => socket.listen(onData));
      },
      onError: (error) => throw error,
      onDone: () async => await close()
    );
  }

  void write(String message, {@required String remoteAddress}) {
    _mapIpSocket[remoteAddress].write(message);
    _mapIpSocket[remoteAddress].flush().catchError((error) => throw error);
  }

  Future<void> close() async {
    _mapIpStream.forEach((ip, stream) => stream.cancel());
    _mapIpStream.clear();
    _mapIpSocket.forEach((ipAddress, socket) => socket.destroy());
    _mapIpSocket.clear();

    await _listenStreamSub.cancel();
    await _serverSocket.close().catchError((error) => throw error);
  }

  Future<void> closeSocket(String remoteAddress) async {
    await _mapIpStream[remoteAddress].cancel();
    _mapIpStream.remove(remoteAddress);
    _mapIpSocket[remoteAddress].destroy();
    _mapIpSocket.remove(remoteAddress);
  }
}
