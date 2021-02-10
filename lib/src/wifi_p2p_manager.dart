import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_wifi_p2p/src/wifi_p2p_device.dart';


class WifiP2PManager {
  static const String _nameMain = 'flutter.wifi.p2p/main.channel';
  static const MethodChannel _chMain = const MethodChannel(_nameMain);

  static const String _nameDiscovery = 'flutter.wifi.p2p/peers';
  static const EventChannel _chDiscovery = const EventChannel(_nameDiscovery);

  WifiP2PManager();

  Future<void> initialize() async => await _chMain.invokeMethod('initialize');

  Future<void> discovery() async => await _chMain.invokeMethod('discovery');

  Stream<WifiP2pDevice> discoveryStream() async* {
    await for (Map map in _chDiscovery.receiveBroadcastStream()) {
      yield WifiP2pDevice.fromMap(map);
    } 
  }
}
