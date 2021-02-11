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

/*------------------------------Getters & Setters-----------------------------*/

  int get port => _port;

  HashMap<String, Socket> get mapIpSocket => _mapIpSocket;

/*-------------------------------Public methods-------------------------------*/

  Future<void> openServer() async {
    _serverSocket = await ServerSocket.bind(_hostIp, _port, shared: true);
  }

  Future<void> closeServer() async {
    await _streamSub.cancel();

    _mapIpSocket.forEach((ipAddress, socket) => socket.destroy());
    _mapIpSocket.clear();

    _serverSocket = await _serverSocket.close();
    _serverSocket = null;
  }

  Future<void> listen(void Function(Uint8List) onData) async {
    try {
      await _listen(onData);
    } on SocketException catch (error) {
      print(error.toString());
      _mapIpSocket.remove(error.address.address);
      _mapIpStream.remove(error.address.address);
    } catch (error) {
      print('here');
    }
  }

  Future<void> write(String message, String remoteAddress) async {
    try {
      _mapIpSocket[remoteAddress].write(message);
    } catch (error) {
      await closeClient(remoteAddress);
    }
  }

  Future<void> closeClient(String remoteAddress) async {
    await _mapIpStream[remoteAddress].cancel();
    _mapIpSocket[remoteAddress].destroy();
    _mapIpSocket.remove(remoteAddress);
    _mapIpStream.remove(remoteAddress);
  }

/*------------------------------Private methods-------------------------------*/

  Future<void> _listen(void Function(Uint8List) onData) async {
    _streamSub = _serverSocket.listen(
      (socket) {
        String remoteAddress = socket.remoteAddress.address;
        _mapIpSocket.putIfAbsent(remoteAddress, () => socket);
        _mapIpStream.putIfAbsent(remoteAddress, () => socket.listen(onData));
      },
      onError: (error) => throw error,
      onDone: () async => await closeServer()
    );
  }
}
