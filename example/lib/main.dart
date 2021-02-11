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
  WifiP2PManager _wifiP2PManager = WifiP2PManager();
  WifiP2pServer _wifiP2pServer;
  WifiP2pClient _wifiP2pClient;
  List<WifiP2pDevice> _wifiP2pDevices = [];

  String _ownIp;
  String _groupOwnerIp;
  int _port = 4444;

  void _listen() {
    _wifiP2PManager.discoveryStream.listen(
      (wifiP2pDevice) {
        print(wifiP2pDevice.name + ', ' + wifiP2pDevice.mac);
        if (!_wifiP2pDevices.contains(wifiP2pDevice)) {
          _wifiP2pDevices.add(wifiP2pDevice);
        }

        setState(() => _wifiP2pDevices = _wifiP2pDevices);
      }
    );

    _wifiP2PManager.wifiStateStream.listen(
      (state) => print(state)
    );

    _wifiP2PManager.wifiP2pConnectionStream.listen(
      (wifiP2pInfo) async {
        print(
          'groupFormed: ${wifiP2pInfo.groupFormed}, ' + 
          'groupOwnerAddress: ${wifiP2pInfo.groupOwnerAddress}, ' + 
          'isGroupOwner: ${wifiP2pInfo.isGroupOwner}'
        );

        if (wifiP2pInfo.isGroupOwner) {
          _groupOwnerIp = _ownIp = wifiP2pInfo.groupOwnerAddress;
          setState(() => _ownIp = _ownIp);
        } else {
          _groupOwnerIp = wifiP2pInfo.groupOwnerAddress;
          _ownIp = await _wifiP2PManager.getOwnIp();
          setState(() => _ownIp = _ownIp);
        }
      }
    );

    _wifiP2PManager.thisDeviceChangeStream.listen(
      (wifiP2pDevice) => print(wifiP2pDevice.name + ', ' + wifiP2pDevice.mac)
    );
  }

  void _serverStartListening() async {
    _wifiP2pServer = WifiP2pServer(_ownIp, _port);
    await _wifiP2pServer.openServer();
    _wifiP2pServer.listen((data) {
      print(new String.fromCharCodes(data).trim());
    });
  }

  void _writeToClient() async {
    _wifiP2pServer.write('Server $_ownIp: Hello world!', '192.168.49.200');
  }

  void _connectClient() async {
    _wifiP2pClient = WifiP2pClient(_groupOwnerIp, _port);
    await _wifiP2pClient.connect();
    _wifiP2pClient.listen((data) {
      print(new String.fromCharCodes(data).trim());
    });
  }

  void _writeToServer() async {
    _wifiP2pClient.write('Client $_ownIp: Hello world!');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
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
              child: Center(child: Text('Initialize')),
              onPressed: _wifiP2PManager.initialize,
            ),
            RaisedButton(
              child: Center(child: Text('Listen')),
              onPressed: _listen,
            ),
            RaisedButton(
              child: Center(child: Text('Discovery')),
              onPressed: _wifiP2PManager.discovery,
            ),
            RaisedButton(
              child: Center(child: Text('Open server')),
              onPressed: _serverStartListening,
            ),
            RaisedButton(
              child: Center(child: Text('Write to client')),
              onPressed: _writeToClient,
            ),
            RaisedButton(
              child: Center(child: Text('Connect client')),
              onPressed: _connectClient,
            ),
            RaisedButton(
              child: Center(child: Text('Write to server')),
              onPressed: _writeToServer,
            ),
            RaisedButton(
              child: Center(child: Text('Disconnect')),
              onPressed: () async {
                if (_wifiP2pClient != null)
                  await _wifiP2pClient.close();
                if (_wifiP2pServer != null)
                  await _wifiP2pServer.closeServer();
                await _wifiP2PManager.removeGroup();
              },
            ),
            Expanded(
              child: ListView(
                children: _wifiP2pDevices.map((device) {
                  return Card(
                    child: ListTile(
                      title: Center(child: Text(device.name)),
                      subtitle: Center(child: Text(device.mac)),
                      onTap: () {
                        print("Connect to device: ${device.mac}");
                        _wifiP2PManager.connect(device.mac);
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
