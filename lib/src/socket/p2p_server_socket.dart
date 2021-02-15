import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_wifi_p2p/src/socket/isocket.dart';
import 'package:meta/meta.dart';


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

  List<String> get activeConnection 
    => _mapIpSocket.entries.map((e) => e.key).toList();

/*-------------------------------Public methods-------------------------------*/

  Future<void> openServer() async {
    _serverSocket = await ServerSocket.bind(_address, _port, shared: true)
      .catchError((error) => throw error);
  }

  void listen(
    void Function(Uint8List) onData, {void Function() onDone}
  ) {
    _listenStreamSub = _serverSocket.listen(
      (socket) {
        String remoteAddress = socket.remoteAddress.address;
        _mapIpSocket.putIfAbsent(remoteAddress, () => socket);
        _mapIpStream.putIfAbsent(remoteAddress, () => socket.listen(onData));
      },
      onDone: () async => (onDone != null) ? onDone() : await close()
    );
  }

  void write(String message, {@required String remoteAddress}) {
    _mapIpSocket[remoteAddress].write(message);
    _mapIpSocket[remoteAddress].flush();
  }

  Future<void> close() async {
    _mapIpStream.forEach((ip, stream) => stream.cancel());
    _mapIpStream.clear();

    _mapIpSocket.forEach((ipAddress, socket) async {
      socket.destroy();
      try {
        await socket.done;
      } catch (error) {
        print(error.toString());
      }
    });
    _mapIpSocket.clear();

    await _listenStreamSub.cancel();
    await _serverSocket.close();
  }

  Future<void> closeSocket(String remoteAddress) async {
    await _mapIpStream[remoteAddress].cancel();
    _mapIpStream.remove(remoteAddress);
    _mapIpSocket[remoteAddress].destroy();
    try {
      await _mapIpSocket[remoteAddress].done;
    } catch (error) {
      print(error.toString());
    }
    _mapIpSocket.remove(remoteAddress);
  }
}
