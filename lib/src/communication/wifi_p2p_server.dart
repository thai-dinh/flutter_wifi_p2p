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
  StreamSubscription<Socket> _streamSub;

  WifiP2pServer(this._hostIp, this._port) {
    _mapIpStream = HashMap();
    _mapIpSocket = HashMap();
  }

  int get port => _port;

  HashMap<String, Socket> get mapIpSocket => _mapIpSocket;

  Future<void> openServer() async {
    _serverSocket = await ServerSocket.bind(_hostIp, _port, shared: true);
  }

  Future<void> closeServer() async {
    await _streamSub.cancel();
    await _serverSocket.close();
  }

  void listen(void Function(Uint8List) onData) {
    _streamSub = _serverSocket.listen((socket) {
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
    _mapIpSocket[remoteAddress].destroy();
    _mapIpSocket.remove(remoteAddress);
    _mapIpStream.remove(remoteAddress);
  }
}
