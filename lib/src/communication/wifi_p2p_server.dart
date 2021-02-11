import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';


class WifiP2pServer {
  final String _hostIp;
  final int _port;

  HashMap<String, StreamSubscription<Uint8List>> _mapIpStream;
  HashMap<String, Socket> _mapIpSocket;
  ServerSocket _serverSocket;

  WifiP2pServer(this._hostIp, this._port) {
    _mapIpStream = HashMap();
    _mapIpSocket = HashMap();
  }

  int get port => _port;

  Future<void> openServer() async {
    _serverSocket = await ServerSocket.bind(_hostIp, _port);
  }

  Future<void> closeServer() async => await _serverSocket.close();

  void listen(void Function(Uint8List) onData) {
    _serverSocket.listen((socket) {
      String remoteAddress = socket.remoteAddress.address;
      _mapIpSocket.putIfAbsent(remoteAddress, () => socket);
      _mapIpStream.putIfAbsent(remoteAddress, () => socket.listen(onData));
    });
  }

  void write(String message, String remoteAddress) {
    _mapIpSocket[remoteAddress].write(message);
  }

  Future<void> closeClient(String remoteAddress) async {
    await _mapIpStream[remoteAddress].cancel();
    await _mapIpSocket[remoteAddress].close();
    _mapIpSocket.remove(remoteAddress);
    _mapIpStream.remove(remoteAddress);
  }
}
