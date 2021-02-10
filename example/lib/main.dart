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
  List<WifiP2pDevice> _wifiP2pDevices = [];

  void _listen() {
    _wifiP2PManager.discoveryStream().asBroadcastStream().listen(
      (wifiP2pDevice) {
        print(wifiP2pDevice.name + ', ' + wifiP2pDevice.mac);
        if (!_wifiP2pDevices.contains(wifiP2pDevice)) {
          _wifiP2pDevices.add(wifiP2pDevice);
        }

        setState(() {
          _wifiP2pDevices = _wifiP2pDevices;
        });
      }
    );
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
              child: Center(
                child: ListTile(
                  title: Text('Initialize'),
                  onTap: _wifiP2PManager.initialize,
                ),
              ),
            ),
            Card(
              child: Center(
                child: ListTile(
                  title: Text('Listen'),
                  onTap: _listen,
                ),
              ),
            ),
            Card(
              child: Center(
                child: ListTile(
                  title: Text('Discovery'),
                  onTap: _wifiP2PManager.discovery,
                ),
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
