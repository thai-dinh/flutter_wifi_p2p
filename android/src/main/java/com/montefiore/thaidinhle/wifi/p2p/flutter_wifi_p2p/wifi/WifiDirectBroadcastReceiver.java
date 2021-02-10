package com.montefiore.thaidinhle.wifi.p2p.flutter_wifi_p2p.wifi;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.net.NetworkInfo;
import android.net.wifi.WifiManager;
import android.net.wifi.p2p.WifiP2pDevice;
import android.net.wifi.p2p.WifiP2pDeviceList;
import android.net.wifi.p2p.WifiP2pInfo;
import android.net.wifi.p2p.WifiP2pManager;
import android.net.wifi.p2p.WifiP2pManager.Channel;
import android.net.wifi.p2p.WifiP2pManager.PeerListListener;
import android.util.Log;

import io.flutter.plugin.common.EventChannel.EventSink;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;


public class WifiDirectBroadcastReceiver extends BroadcastReceiver {
    private static final String TAG = "[FlutterWifiP2P][BroadcastReceiver]";

    private Channel channel;
    private HashMap<String, EventSink> mapNameEventSink;
    private List<WifiP2pDevice> peers;
    private WifiP2pManager wifiP2pManager;

    public WifiDirectBroadcastReceiver(
        Channel channel, HashMap<String, EventSink> mapNameEventSink, WifiP2pManager wifiP2pManager
    ) {
        this.channel = channel;
        this.mapNameEventSink = mapNameEventSink;
        this.wifiP2pManager = wifiP2pManager;
        this.peers = new ArrayList<WifiP2pDevice>();
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        String action = intent.getAction();
        if (WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION.equals(action)) {
            Log.d(TAG, "onReceive(): STATE_CHANGED");
            int state = intent.getIntExtra(WifiP2pManager.EXTRA_WIFI_STATE, -1);
            // if (state == WifiP2pManager.WIFI_P2P_STATE_ENABLED)
        } else if (WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION.equals(action)) {
            Log.d(TAG, "onReceive(): PEERS_CHANGED");

            if (wifiP2pManager != null) {
                wifiP2pManager.requestPeers(channel, peerListListener);
            }
        } else if (WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION.equals(action)) {
            Log.d(TAG, "onReceive(): CONNECTION_CHANGED");

            NetworkInfo networkInfo = (NetworkInfo) intent.getParcelableExtra(WifiP2pManager.EXTRA_NETWORK_INFO);

            if (networkInfo.isConnected()) {
                wifiP2pManager.requestConnectionInfo(channel, connectionInfoListener);
            }
        } else if (WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION.equals(action)) {
            Log.d(TAG, "onReceive(): THIS_DEVICE_CHANGED");
            // (WifiP2pDevice) intent.getParcelableExtra(WifiP2pManager.EXTRA_WIFI_P2P_DEVICE);
        }
    }

    private PeerListListener peerListListener = new PeerListListener() {
        @Override
        public void onPeersAvailable(WifiP2pDeviceList peerList) {
            List<WifiP2pDevice> refreshedPeers = new ArrayList<>(peerList.getDeviceList());
            if (!refreshedPeers.equals(peers)) {
                peers.clear();
                peers.addAll(refreshedPeers);

                for (WifiP2pDevice wifiP2pDevice : refreshedPeers) {
                    Log.d(TAG, "onPeersAvailable(): " + wifiP2pDevice.deviceName);

                    HashMap<String, Object> mapInfoValue = new HashMap<>();
                    mapInfoValue.put("name", wifiP2pDevice.deviceName);
                    mapInfoValue.put("mac", wifiP2pDevice.deviceAddress.toUpperCase());
    
                    EventSink eventSink = mapNameEventSink.get("PEERS_CHANGED");
                    eventSink.success(mapInfoValue);
                }
            }
        }
    };

    private WifiP2pManager.ConnectionInfoListener connectionInfoListener = new WifiP2pManager.ConnectionInfoListener() {
        @Override
        public void onConnectionInfoAvailable(final WifiP2pInfo info) {
            Log.d(TAG, "Address groupOwner :" + String.valueOf(info.groupOwnerAddress.getHostAddress()));

            if (info.isGroupOwner) {
                Log.d(TAG, "This device is the groupOwner");
            } else {
                Log.d(TAG, "This device is not the groupOwner");
            }
        }
    };
}
