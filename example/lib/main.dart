import 'package:flutter/material.dart';

import 'package:flutter_wifi_p2p/flutter_wifi_p2p.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  FlutterWifiP2p _flutterWifiP2p = FlutterWifiP2p();
  List<WifiP2pDevice> _listDevices = [];
  P2pServerSocket _serverSocket;
  P2pClientSocket _clientSocket;
  String _ownIp;
  String _groupOwnerIp;
  bool _isGroupFormed = false;
  bool _isGroupOwner = false;
  int _port = 4444;

  void _listen() {
    _flutterWifiP2p.verbose = true;
    _flutterWifiP2p.register();
    _flutterWifiP2p.discoveryStream.listen(
      (devices) {
        devices.forEach(
          (device) => print(device.name + ', ' + device.mac)
        );

        setState(() => _listDevices = devices);
      }
    );

    _flutterWifiP2p.wifiStateStream.listen(
      (state) => print('Wifi state: $state')
    );

    _flutterWifiP2p.wifiP2pConnectionStream.listen(
      (wifiP2pInfo) async {
        print(
          'groupFormed: ${wifiP2pInfo.groupFormed}, ' + 
          'groupOwnerAddress: ${wifiP2pInfo.groupOwnerAddress}, ' + 
          'isGroupOwner: ${wifiP2pInfo.isGroupOwner}'
        );

        _isGroupFormed = wifiP2pInfo.groupFormed;
        _isGroupOwner = wifiP2pInfo.isGroupOwner;
        if (_isGroupOwner) {
          _groupOwnerIp = _ownIp = wifiP2pInfo.groupOwnerAddress;
          setState(() => _ownIp = _ownIp);
        } else {
          _groupOwnerIp = wifiP2pInfo.groupOwnerAddress;
          _ownIp = await _flutterWifiP2p.ownIp;
          setState(() => _ownIp = _ownIp);
        }
      }
    );

    _flutterWifiP2p.thisDeviceChangeStream.listen(
      (wifiP2pDevice) => print(wifiP2pDevice.name + ', ' + wifiP2pDevice.mac)
    );
  }

  void _serverStartListening() async {
    _serverSocket = P2pServerSocket(_ownIp, _port);
    await _serverSocket.openServer();
    _serverSocket.listen((data) {
      _displayMessage(new String.fromCharCodes(data).trim());
    });
  }

  void _writeToClient() async {
    List<String> activeConnection = _serverSocket.activeConnection;
    activeConnection.forEach(
      (ip) => _serverSocket.write(
        'Server $_ownIp: Hello world!', remoteAddress: ip
      )
    );
  }

  void _connectToServer() async {
    _clientSocket = P2pClientSocket(_groupOwnerIp, _port);
    await _clientSocket.connect(1000);
    _clientSocket.listen((data) {
      _displayMessage(new String.fromCharCodes(data).trim());
    });
  }

  void _writeToServer() async {
    _clientSocket.write('Client $_ownIp: Hello world!');
  }

  void _displayMessage(final String message) {
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Center(child: Text(message)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('Wifi P2P for Flutter example app'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Card(
              child: ListTile(
                title: Center(child: Text('Own IP: $_ownIp')),
              ),
            ),
            RaisedButton(
              child: Center(child: Text('Listen')),
              onPressed: _listen,
            ),
            RaisedButton(
              child: Center(child: Text('Discovery')),
              onPressed: _flutterWifiP2p.discovery,
            ),
            RaisedButton(
              child: Center(child: Text('Open server')),
              onPressed: () {
                if (_isGroupFormed && _isGroupOwner) 
                  _serverStartListening();
                else 
                  return;
              },
            ),
            RaisedButton(
              child: Center(child: Text('Write to client(s)')),
              onPressed: () {
                if (_isGroupFormed && _isGroupOwner)
                  _writeToClient();
                else
                  return;
              },
            ),
            RaisedButton(
              child: Center(child: Text('Connect to server')),
              onPressed: () {
                if (_isGroupFormed && !_isGroupOwner)
                  _connectToServer();
                else
                  return;
              },
            ),
            RaisedButton(
              child: Center(child: Text('Write to server')),
              onPressed: () {
                if (_isGroupFormed && !_isGroupOwner)
                  _writeToServer();
                else
                  return;
              },
            ),
            RaisedButton(
              child: Center(child: Text('Disconnect')),
              onPressed: () async {
                if (_clientSocket != null)
                  await _clientSocket.close();
                if (_serverSocket != null)
                  await _serverSocket.close();
                await _flutterWifiP2p.removeGroup();
              },
            ),
            Expanded(
              child: ListView(
                children: _listDevices.map((device) {
                  return Card(
                    child: ListTile(
                      title: Center(child: Text(device.name)),
                      subtitle: Center(child: Text(device.mac)),
                      onTap: () {
                        print("Connect to device: ${device.mac}");
                        _flutterWifiP2p.connect(device.mac);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
