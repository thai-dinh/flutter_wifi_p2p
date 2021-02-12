import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_wifi_p2p/src/wifi/wifi_p2p_device.dart';
import 'package:flutter_wifi_p2p/src/wifi/wifi_p2p_info.dart';


class FlutterWifiP2p {
  static const MethodChannel _chMain = const MethodChannel('wifi.p2p/main');
  static const EventChannel _chWifiState = const EventChannel('wifi.p2p/state');
  static const EventChannel _chDiscovery = const EventChannel('wifi.p2p/peers');
  static const EventChannel _chConnection = const EventChannel('wifi.p2p/connection');
  static const EventChannel _chChange = const EventChannel('wifi.p2p/this.device');

  FlutterWifiP2p();

/*------------------------------Getters & Setters-----------------------------*/

  Stream<List<WifiP2pDevice>> get discoveryStream async* {
    await for (List list in _chDiscovery.receiveBroadcastStream()) {
      List<WifiP2pDevice> listPeers = List.empty(growable: true);
      list.forEach((map) => listPeers.add(WifiP2pDevice.fromMap(map)));
      yield listPeers;
    }
  }

  Stream<bool> get wifiStateStream async* {
    await for (bool state in _chWifiState.receiveBroadcastStream()) {
      yield state;
    }
  }

  Stream<WifiP2pInfo> get wifiP2pConnectionStream async* {
    await for (Map map in _chConnection.receiveBroadcastStream()) {
      yield WifiP2pInfo.fromMap(map);
    }
  }

  Stream<WifiP2pDevice> get thisDeviceChangeStream async* {
    await for (Map map in _chChange.receiveBroadcastStream()) {
      yield WifiP2pDevice.fromMap(map);
    }
  }

  set verbose(bool verbose) => _chMain.invokeMethod('setVerbose', verbose);

/*-------------------------------Public methods-------------------------------*/

  Future<void> register() async => await _chMain.invokeMethod('register');

  Future<void> unregister() async => await _chMain.invokeMethod('unregister');

  Future<void> discovery() async => await _chMain.invokeMethod('discovery');

  Future<void> connect(final String remoteAddress) async {
    await _chMain.invokeMethod('connect', remoteAddress);
  }

  Future<void> removeGroup() async => await _chMain.invokeMethod('removeGroup');

  Future<String> getOwnIp() async {
    String ipAddress;
    for (NetworkInterface interface in await NetworkInterface.list()) {
      if (interface.name.compareTo('p2p-wlan0-0') == 0)
        ipAddress = interface.addresses.first.address;
    }

    return ipAddress;
  }
}
