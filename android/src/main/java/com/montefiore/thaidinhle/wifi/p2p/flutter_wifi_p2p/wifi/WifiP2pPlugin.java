package com.montefiore.thaidinhle.wifi.p2p.flutter_wifi_p2p.wifi;

import android.content.Context;
import android.content.IntentFilter;
import android.net.wifi.WifiManager;
import android.net.wifi.p2p.WifiP2pConfig;
import android.net.wifi.p2p.WifiP2pManager;
import android.net.wifi.p2p.WifiP2pManager.Channel;
import android.util.Log;

import io.flutter.plugin.common.EventChannel.EventSink;

import java.util.HashMap;
import java.util.Timer;
import java.util.TimerTask;

import static android.net.wifi.p2p.WifiP2pManager.BUSY;
import static android.net.wifi.p2p.WifiP2pManager.ERROR;
import static android.net.wifi.p2p.WifiP2pManager.P2P_UNSUPPORTED;
import static android.os.Looper.getMainLooper;


public class WifiP2pPlugin {
    private static final String TAG = "[FlutterWifiP2P][WifiP2pPlugin]";

    private Channel channel;
    private Context context;
    private WifiDirectBroadcastReceiver broadcastReceiver;
    private WifiP2pManager wifiP2pManager;

    public WifiP2pPlugin(Context context) {
        this.context = context;
        this.wifiP2pManager = (WifiP2pManager) context.getSystemService(Context.WIFI_P2P_SERVICE);
        this.channel = wifiP2pManager.initialize(context, getMainLooper(), null);
    }

    public void register(HashMap<String, EventSink> mapNameEventSink) {
        Log.d(TAG, "register()");

        final IntentFilter intentFilter = new IntentFilter();

        // Indicates a change in the Wi-Fi P2P status.
        intentFilter.addAction(WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION);
    
        // Indicates a change in the list of available peers.
        intentFilter.addAction(WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION);
    
        // Indicates the state of Wi-Fi P2P connectivity has changed.
        intentFilter.addAction(WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION);
    
        // Indicates this device's details have changed.
        intentFilter.addAction(WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION);
    
        broadcastReceiver = new WifiDirectBroadcastReceiver(channel, mapNameEventSink, wifiP2pManager);

        context.registerReceiver(broadcastReceiver, intentFilter);
    }

    public void unregister() {
        context.unregisterReceiver(broadcastReceiver);
    }

    public void startDiscovery() {
        wifiP2pManager.discoverPeers(channel, new WifiP2pManager.ActionListener() {
            @Override
            public void onSuccess() {
                Log.d(TAG, "startDiscovery(): success");
            }

            @Override
            public void onFailure(int reasonCode) {
                Log.d(TAG, "startDiscovery(): failure -> " + errorCode(reasonCode));
            }
        });
    }

    public void stopDiscovery() {
        wifiP2pManager.stopPeerDiscovery(channel, new WifiP2pManager.ActionListener() {
            @Override
            public void onSuccess() {
                Log.d(TAG, "stopDiscovery(): success");
            }

            @Override
            public void onFailure(int reason) {
                Log.e(TAG, "stopDiscovery(): failure -> " + errorCode(reason));
            }
        });
    }

    public void connect(final String remoteAddress) {
        final WifiP2pConfig config = new WifiP2pConfig();
        config.deviceAddress = remoteAddress.toLowerCase();

        wifiP2pManager.connect(channel, config, new WifiP2pManager.ActionListener() {
            @Override
            public void onSuccess() {
                Log.d(TAG, "connect(): success");
            }

            @Override
            public void onFailure(int reasonCode) {
                Log.e(TAG, "connect(): failure -> " + errorCode(reasonCode));
            }
        });
    }

    private String errorCode(int reasonCode) {
        switch (reasonCode) {
            case ERROR:
                return "P2P internal error";
            case P2P_UNSUPPORTED:
                return "P2P is not supported";
            case BUSY:
                return "P2P is busy";
        }

        return "Unknown error";
    }
}
