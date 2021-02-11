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
        } else {
          _groupOwnerIp = wifiP2pInfo.groupOwnerAddress;
          _ownIp = await _wifiP2PManager.getOwnIp();
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

  void _connectClient() async {
    _wifiP2pClient = WifiP2pClient(_groupOwnerIp, _port);
    await _wifiP2pClient.connect();
    _wifiP2pClient.listen((data) {
      print(new String.fromCharCodes(data).trim());
    });
    _wifiP2pClient.write('Hello world!');
    _wifiP2pClient.close();
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
            Card(
              child: ListTile(
                title: Center(child: Text('Initialize')),
                onTap: _wifiP2PManager.initialize,
              ),
            ),
            Card(
              child: ListTile(
                title: Center(child: Text('Listen')),
                onTap: _listen,
              ),
            ),
            Card(
              child: ListTile(
                title: Center(child: Text('Discovery')),
                onTap: _wifiP2PManager.discovery,
              ),
            ),
            Card(
              child: ListTile(
                title: Center(child: Text('Open server')),
                onTap: _serverStartListening,
              ),
            ),
            Card(
              child: ListTile(
                title: Center(child: Text('Connect client')),
                onTap: _connectClient,
              ),
            ),
            Card(
              child: ListTile(
                title: Center(child: Text('Disconnect')),
                onTap: _wifiP2PManager.removeGroup,
              ),
            ),
            Expanded(
              child: ListView(
                children: _wifiP2pDevices.map((device) {
                  return Card(
                    child: ListTile(
                      title: Text(device.name),
                      subtitle: Text(device.mac),
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
