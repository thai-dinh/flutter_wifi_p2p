
import 'dart:async';

import 'package:flutter/services.dart';

class FlutterWifiP2p {
  static const MethodChannel _channel =
      const MethodChannel('flutter_wifi_p2p');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
