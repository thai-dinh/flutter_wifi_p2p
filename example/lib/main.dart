import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
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

  void _listen() {
    _wifiP2PManager.discoveryStream().asBroadcastStream().listen(
      (wifiP2pDevice) {
        print(wifiP2pDevice.name + ', ' + wifiP2pDevice.mac);
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
        body: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  RaisedButton(
                    child: Text('Initialize'),
                    onPressed: _wifiP2PManager.initialize,
                  ),
                  RaisedButton(
                    child: Text('Listen'),
                    onPressed: _listen,
                  ),
                  RaisedButton(
                    child: Text('Discovery'),
                    onPressed: _wifiP2PManager.discovery,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
