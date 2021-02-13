package com.montefiore.thaidinhle.wifi.p2p.flutter_wifi_p2p.wifi;

import android.content.Context;
import android.content.IntentFilter;
import android.net.wifi.WifiManager;
import android.net.wifi.WpsInfo;
import android.net.wifi.p2p.WifiP2pConfig;
import android.net.wifi.p2p.WifiP2pGroup;
import android.net.wifi.p2p.WifiP2pManager;
import android.net.wifi.p2p.WifiP2pManager.Channel;
import android.util.Log;

import io.flutter.plugin.common.EventChannel.EventSink;

import java.net.NetworkInterface;
import java.net.SocketException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.Timer;
import java.util.TimerTask;

import static android.net.wifi.p2p.WifiP2pManager.BUSY;
import static android.net.wifi.p2p.WifiP2pManager.ERROR;
import static android.net.wifi.p2p.WifiP2pManager.P2P_UNSUPPORTED;
import static android.os.Looper.getMainLooper;


public class WifiP2pPlugin {
    private static final String TAG = "[FlutterWifiP2P][WifiP2P]";

    private boolean verbose;
    private boolean registered;
    private Channel channel;
    private Context context;
    private WifiDirectBroadcastReceiver broadcastReceiver;
    private WifiP2pManager wifiP2pManager;

    public WifiP2pPlugin(Context context) {
        this.verbose = false;
        this.registered = false;
        this.context = context;
        this.wifiP2pManager = (WifiP2pManager) context.getSystemService(Context.WIFI_P2P_SERVICE);
        this.channel = wifiP2pManager.initialize(context, getMainLooper(), null);
    }

    public void setVerbose(boolean verbose) {
        if (verbose) Log.d(TAG, "setVerbose()");
        this.verbose = verbose;
    }

    public String getMacAddress() {
        try {
            ArrayList<NetworkInterface> networkInterfaces = Collections.list(NetworkInterface.getNetworkInterfaces());
            for (NetworkInterface networkInterface : networkInterfaces) {
                Log.d(TAG, networkInterface.getName());

               if (networkInterface.getName().compareTo("p2p-wlan0-0") == 0) {
                byte[] mac = networkInterface.getHardwareAddress();
                if (mac == null) {
                    return "";
                }

                StringBuilder sb = new StringBuilder();
                for (byte b : mac) {
                    if (sb.length() > 0)
                        sb.append(':');
                    sb.append(String.format("%02x", b));
                }

                return sb.toString();
               }
            }
        } catch (SocketException exception) {
            if (verbose) Log.d(TAG, "Error while fetching MAC address" + exception.toString());
        }

        return "";
    }

    public void register(HashMap<String, EventSink> mapNameEventSink) {
        if (verbose) Log.d(TAG, "register()");

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
        broadcastReceiver.setVerbose(verbose);

        context.registerReceiver(broadcastReceiver, intentFilter);

        registered = true;
    }

    public void unregister() {
        if (verbose) Log.d(TAG, "unregister()");

        if (registered) {
            context.unregisterReceiver(broadcastReceiver);
            registered = false;
        }
    }

    public void startDiscovery() {
        wifiP2pManager.discoverPeers(channel, new WifiP2pManager.ActionListener() {
            @Override
            public void onSuccess() {
                if (verbose) Log.d(TAG, "startDiscovery(): success");
            }

            @Override
            public void onFailure(int reasonCode) {
                if (verbose) Log.d(TAG, "startDiscovery(): failure -> " + errorCode(reasonCode));
            }
        });
    }

    public void stopDiscovery() {
        wifiP2pManager.stopPeerDiscovery(channel, new WifiP2pManager.ActionListener() {
            @Override
            public void onSuccess() {
                if (verbose) Log.d(TAG, "stopDiscovery(): success");
            }

            @Override
            public void onFailure(int reason) {
                if (verbose) Log.e(TAG, "stopDiscovery(): failure -> " + errorCode(reason));
            }
        });
    }

    public void connect(final String remoteAddress) {
        final WifiP2pConfig config = new WifiP2pConfig();
        config.deviceAddress = remoteAddress.toLowerCase();
        config.wps.setup = WpsInfo.PBC;

        wifiP2pManager.connect(channel, config, new WifiP2pManager.ActionListener() {
            @Override
            public void onSuccess() {
                if (verbose) Log.d(TAG, "connect(): success");
            }

            @Override
            public void onFailure(int reasonCode) {
                if (verbose) Log.e(TAG, "connect(): failure -> " + errorCode(reasonCode));
            }
        });
    }

    public void removeGroup() {
        wifiP2pManager.requestGroupInfo(channel, new WifiP2pManager.GroupInfoListener() {
            @Override
            public void onGroupInfoAvailable(WifiP2pGroup group) {
                if (group != null) {
                    wifiP2pManager.removeGroup(channel, new WifiP2pManager.ActionListener() {
                        @Override
                        public void onSuccess() {
                            if (verbose) Log.d(TAG, "removeGroup(): success");
                        }

                        @Override
                        public void onFailure(int reason) {
                            if (verbose) Log.e(TAG, "removeGroup(): failure -> " + errorCode(reason));
                        }
                    });
                }
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
