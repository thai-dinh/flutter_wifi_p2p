package com.montefiore.thaidinhle.wifi.p2p.flutter_wifi_p2p;

import android.content.Context;
import android.util.Log;
import androidx.annotation.NonNull;

import com.montefiore.thaidinhle.wifi.p2p.flutter_wifi_p2p.wifi.WifiP2pPlugin;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import java.util.HashMap;
import java.util.Map;


public class FlutterWifiP2pPlugin implements FlutterPlugin, MethodCallHandler {
  private static final String TAG = "[FlutterWifiP2P][FlutterWifiP2pPlugin]";
  private static final String CHANNEL_NAME = "flutter.wifi.p2p/main.channel";

  private BinaryMessenger messenger;
  private Context context;
  private HashMap<String, EventChannel> mapNameEventChannel;
  private HashMap<String, EventSink> mapNameEventSink;
  private MethodChannel channel;
  private WifiP2pPlugin wifiP2pPlugin;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    messenger = flutterPluginBinding.getBinaryMessenger();
    channel = new MethodChannel(messenger, CHANNEL_NAME);
    channel.setMethodCallHandler(this);

    context = flutterPluginBinding.getApplicationContext();

    wifiP2pPlugin = new WifiP2pPlugin(context);

    mapNameEventChannel = new HashMap<String, EventChannel>();
    mapNameEventSink = new HashMap<String, EventSink>();
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case "initialize":
        initChannels(messenger);
        wifiP2pPlugin.register(mapNameEventSink);
        result.success(null);
        break;

      case "discovery":
        wifiP2pPlugin.startDiscovery();
        break;

      case "connect":
        final String remoteAddress = call.arguments();
        wifiP2pPlugin.connect(remoteAddress);
        break;

      case "removeGroup":
        break;

      case "openServerSocket":
        break;

      case "closeServerSocket":
        break;

      default:
        result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    for (Map.Entry<String, EventChannel> entry : mapNameEventChannel.entrySet()) {
      EventChannel eventChannel = entry.getValue();
      eventChannel.setStreamHandler(null);
    }

    wifiP2pPlugin.stopDiscovery();
    wifiP2pPlugin.unregister();
    channel.setMethodCallHandler(null);
  }

  private void initChannels(BinaryMessenger messenger) {
    Log.d(TAG, "initChannels()");

    final String[] channelIdentifiers = new String[] { 
      "STATE_CHANGED", "PEERS_CHANGED", "CONNECTION_CHANGED", "THIS_DEVICE_CHANGED"
    };

    final String[] channelNames = new String[] { 
      "flutter.wifi.p2p/state", "flutter.wifi.p2p/peers", "flutter.wifi.p2p/connection", 
      "flutter.wifi.p2p/this.device"
    };

    for (int i = 0; i < channelIdentifiers.length; i++) {
      EventChannel channel = new EventChannel(messenger, channelNames[i]);
      final int j = i;

      channel.setStreamHandler(new StreamHandler() {
        @Override
        public void onListen(Object arguments, EventSink events) {
          mapNameEventSink.put(channelIdentifiers[j], events);
        }

        @Override
        public void onCancel(Object arguments) {
          EventSink eventSink = mapNameEventSink.get(channelIdentifiers[j]);
          EventChannel eventChannel = mapNameEventChannel.get(channelIdentifiers[j]);
          eventSink = null;
          eventChannel.setStreamHandler(null);
          eventChannel = null;
        }
      });

      mapNameEventChannel.put(channelIdentifiers[i], channel);
    }
  }
}
