import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_wifi_p2p/src/wifi_p2p_device.dart';
import 'package:flutter_wifi_p2p/src/wifi_p2p_info.dart';


class WifiP2PManager {
  static const String _nameMain = 'flutter.wifi.p2p/main.channel';
  static const String _nameWifiState = 'flutter.wifi.p2p/state';
  static const String _nameDiscovery = 'flutter.wifi.p2p/peers';
  static const String _nameConnection = 'flutter.wifi.p2p/connection';
  static const String _nameChange = 'flutter.wifi.p2p/this.device';
  static const MethodChannel _chMain = const MethodChannel(_nameMain);
  static const EventChannel _chWifiState = const EventChannel(_nameWifiState);
  static const EventChannel _chDiscovery = const EventChannel(_nameDiscovery);
  static const EventChannel _chConnection = const EventChannel(_nameConnection);
  static const EventChannel _chChange = const EventChannel(_nameChange);

  WifiP2PManager();

  Stream<WifiP2pDevice> discoveryStream() async* {
    await for (Map map in _chDiscovery.receiveBroadcastStream()) {
      yield WifiP2pDevice.fromMap(map);
    }
  }

  Stream<bool> wifiStateStream() async* {
    await for (bool state in _chWifiState.receiveBroadcastStream()) {
      yield state;
    }
  }

  Stream<WifiP2pInfo> wifiP2pConnectionStream() async* {
    await for (Map map in _chConnection.receiveBroadcastStream()) {
      yield WifiP2pInfo.fromMap(map);
    }
  }

  Stream<WifiP2pDevice> thisDeviceChangeStream() async* {
    await for (Map map in _chChange.receiveBroadcastStream()) {
      yield WifiP2pDevice.fromMap(map);
    }
  }

  Future<void> initialize() async => await _chMain.invokeMethod('initialize');

  Future<void> discovery() async => await _chMain.invokeMethod('discovery');

  Future<void> connect(final String remoteAddress) async {
    await _chMain.invokeMethod('connect', remoteAddress);
  }

  Future<void> removeGroup() async => await _chMain.invokeMethod('removeGroup');
}
