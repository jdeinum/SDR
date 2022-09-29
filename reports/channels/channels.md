# Understanding Scan Behavior in Android Part 2


## The Goals
1. Understand how the sequence of channels that are scanned during an active
	 scan



## 1. Channel Behavior

Now that we have a grasp on the timing between scans, we are interested in which
channels are scanned, and in what order. It makes sense to start from the same
place as before: `startPeriodicSingleScan()`. In this function
`startSingleScan()` is called, which itself calls `startForcedSingleScan()` we
pass whether we want to scan the full band. If this is true, we scan some
combination of full bands. Otherwise, we scan a set of channels given to us:

```java
if (!isFullBandScan) {
  if (!setScanChannels(settings)) {
      isFullBandScan = true;
      // Skip the initial scan since no channel history available
      setInitialScanState(INITIAL_SCAN_STATE_COMPLETE);
  } else {
      mInitialPartialScanChannelCount = settings.channels.length;
  }
}
```

If isFullBandScan is set, we find which bands to scan with the following
function:

```java
private int getScanBand(boolean isFullBandScan) {
  if (isFullBandScan) {
      if (SdkLevel.isAtLeastS()) {
          if (mContext.getResources().getBoolean(R.bool.config_wifiEnable6ghzPscScanning)) {
              return WifiScanner.WIFI_BAND_24_5_WITH_DFS_6_GHZ;
          }
          return WifiScanner.WIFI_BAND_BOTH_WITH_DFS;
      }
      return WifiScanner.WIFI_BAND_ALL;
  } else {
      // Use channel list instead.
      return WifiScanner.WIFI_BAND_UNSPECIFIED;
  }
}
```

So we scan 2.4GHz and 5GHz with DFS, and only scan 6GHz if we can.

One thing to note is that even if an Android scan specifies a particular band,
the entire band may not be scanned if there are country restrictions imposed on
which channels you may scan. [This](https://cs.android.com/android/platform/superproject/+/master:packages/modules/Wifi/service/java/com/android/server/wifi/WifiCountryCode.java)
file contains the details necessary for anything related to the country code.
Country restrictions are handled within the drivers for network devices, so it
is out of Androids hands (which makes sense). However Android is responsible for
telling the drivers if a devices country code changes. (Someone going on
vacation should be able to scan all of the channels available in that country).

Once we call `mScanner.startScan()` , an asynchronous message is sent out, and
handled by the following code in [this](https://cs.android.com/android/platform/superproject/+/master:packages/modules/Wifi/service/java/com/android/server/wifi/scanner/WifiScanningServiceImpl.java;l=361;drc=e7922004aa99249152dfcdbcc67e409452151e62;bpv=1;bpt=1)
file:

```java
private void handleScanStartMessage(ClientInfo ci, Message msg) {

      ....


      if (getCurrentState() == mScanningState) {
          // If there is an active scan that will fulfill the scan request then
          // mark this request as an active scan, otherwise mark it pending.
          if (activeScanSatisfies(scanSettings)) {
              mActiveScans.addRequest(ci, handler, workSource, scanSettings);
          } else {
              mPendingScans.addRequest(ci, handler, workSource, scanSettings);
          }
      } else if (getCurrentState() == mIdleState) {
          // If were not currently scanning then try to start a scan. Otherwise
          // this scan will be scheduled when transitioning back to IdleState
          // after finishing the current scan.
          mPendingScans.addRequest(ci, handler, workSource, scanSettings);
          tryToStartNewScan();
      } else if (getCurrentState() == mDefaultState) {
          // If scanning is disabled and the request is for emergency purposes
          // (checked above), add to pending list. this scan will be scheduled when
          // transitioning to IdleState when wifi manager enables scanning as a part of
          // processing WifiManager.setEmergencyScanRequestInProgress(true)
          mPendingScans.addRequest(ci, handler, workSource, scanSettings);
      }
  } else {
      logCallback("singleScanInvalidRequest",  ci, handler, "bad request");
      replyFailed(msg, WifiScanner.REASON_INVALID_REQUEST, "bad request");
      mWifiMetrics.incrementScanReturnEntry(
              WifiMetricsProto.WifiLog.SCAN_FAILURE_INVALID_CONFIGURATION, 1);
  }
}
```

So it gets appended to either of these:
```java
private RequestList<ScanSettings> mActiveScans = new RequestList<>();
private RequestList<ScanSettings> mPendingScans = new RequestList<>();
```

Searching through the codebase, the only time that entries are scanned in
mPendingScans is in the `void tryToStartNewScan()`. Since this function is
pretty large too, Its definition is in the appendix and we'll go through it
piece by piece.

First, we update which channels we can scan by calling
`mChannelHelper.updateChannels()` which is defined as:

```java
public void updateChannels() {
    int[] channels24G =
                    mWifiNative.getChannelsForBand(WifiScanner.WIFI_BAND_24_GHZ);
    if (channels24G == null) Log.e(TAG, "Failed to get channels for 2.4GHz band");
    int[] channels5G = mWifiNative.getChannelsForBand(WifiScanner.WIFI_BAND_5_GHZ);
    if (channels5G == null) Log.e(TAG, "Failed to get channels for 5GHz band");
    int[] channelsDfs =
                    mWifiNative.getChannelsForBand(WifiScanner.WIFI_BAND_5_GHZ_DFS_ONLY);
    if (channelsDfs == null) Log.e(TAG, "Failed to get channels for 5GHz DFS only band");
    int[] channels6G =
                    mWifiNative.getChannelsForBand(WifiScanner.WIFI_BAND_6_GHZ);
    if (channels6G == null) Log.e(TAG, "Failed to get channels for 6GHz band");
    int[] channels60G =
                    mWifiNative.getChannelsForBand(WifiScanner.WIFI_BAND_60_GHZ);

    ...
 
}
```

We are interested in seeing which channels are scanned for the 2.4GHz and the
5GHz bands. Trying to find either of the channels that the device can scan leads
us to the following
[code](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/wifi/java/src/android/net/wifi/nl80211/WifiNl80211Manager.java;l=103;drc=e7922004aa99249152dfcdbcc67e409452151e62;bpv=1;bpt=1):
```
// Returns an array of available frequencies for DFS channels.
// This also includes passive only frequecies which are not for DFS channels.
// Returrns null on failure.
@Override public int[] getAvailableDFSChannels() throws android.os.RemoteException
{
    return null;
}
```

So the channels which we can scan is returned from a call to the network
interface. We do not know the channels, but can assume they follow the expected
frequencies and move on. Now that we know which channels we can scan, we add all
of the channels that we want to scan (from the scan requests). This is done by
looping through the pending scan requests and extracting the channels from them:


```java
ChannelCollection channels = mChannelHelper.createChannelCollection();
List<WifiNative.HiddenNetwork> hiddenNetworkList = new ArrayList<>();

...

for (RequestInfo<ScanSettings> entry : mPendingScans) {
    settings.scanType = mergeScanTypes(settings.scanType, entry.settings.type);
    settings.enable6GhzRnr = mergeRnrSetting(settings.enable6GhzRnr, entry.settings);
    channels.addChannels(entry.settings);
```

Adding a channel consists of checking whether a band was specified or if a
sequence of channels was provided and take appropriate action.

```java
public void addChannels(WifiScanner.ScanSettings scanSettings) {
    if (scanSettings.band == WifiScanner.WIFI_BAND_UNSPECIFIED) {
            for (int j = 0; j < scanSettings.channels.length; ++j) {
                    addChannel(scanSettings.channels[j].frequency);
            }
            return;
    }
    if (SdkLevel.isAtLeastS()) {
            if (scanSettings.is6GhzPscOnlyEnabled() && is6GhzBandIncluded(scanSettings.band)) {
                    // Modify the band to exclude 6Ghz since not all 6Ghz channels will be added.
                    int band = scanSettings.band & (~WifiScanner.WIFI_BAND_6_GHZ);
                    addBand(band);
                    add6GhzPscChannels();
                    return;
            }
    }
    addBand(scanSettings.band);
```


Adding a band consists of finding the available channels to scan and adding
their frequencies to a list.

```java
public void addBand(int band) {
    mExactBands |= band;
    mAllBands |= band;
    WifiScanner.ChannelSpec[][] bandChannels = getAvailableScanChannels(band);
    for (int i = 0; i < bandChannels.length; ++i) {
            for (int j = 0; j < bandChannels[i].length; ++j) {
                    mChannels.add(bandChannels[i][j].frequency);
            }
    }
}
```











One note of interest is that `channels` is shared by all pending requests,
meaning that all of the requests will be fulfilled in one scan. We'll explore
this once we go through the rest of the function. Once we have our channel
list,we convert it to a bucket list by calling:

```java
channels.fillBucketSettings(bucketSettings, Integer.MAX_VALUE);
```

The actual filling of the bucket occurs in this function located
[here](https://cs.android.com/android/platform/superproject/+/master:packages/modules/Wifi/service/java/com/android/server/wifi/scanner/KnownBandsChannelHelper.java;l=419;drc=e7922004aa99249152dfcdbcc67e409452151e62;bpv=1;bpt=1).

```java
public void fillBucketSettings(WifiNative.BucketSettings bucketSettings, int maxChannels) {
    if ((mChannels.size() > maxChannels || mAllBands == mExactBands) && mAllBands != 0) {
            bucketSettings.band = mAllBands;
            bucketSettings.num_channels = 0;
            bucketSettings.channels = null;
    } else {
            bucketSettings.band = WIFI_BAND_UNSPECIFIED;
            bucketSettings.num_channels = mChannels.size();
            bucketSettings.channels = new WifiNative.ChannelSettings[mChannels.size()];
            for (int i = 0; i < mChannels.size(); ++i) {
                    WifiNative.ChannelSettings channelSettings = new WifiNative.ChannelSettings();
                    channelSettings.frequency = mChannels.valueAt(i);
                    bucketSettings.channels[i] = channelSettings;
            }
    }
}
```

So if there's too many channels, we just scan all the bands that we can.
Otherwise, we 






## Appendix
Full definition for tryToStartNewScan() 

```
void tryToStartNewScan() {
    if (mPendingScans.size() == 0) { // no pending requests
            return;
    }
    mChannelHelper.updateChannels();
    // TODO move merging logic to a scheduler
    WifiNative.ScanSettings settings = new WifiNative.ScanSettings();
    settings.num_buckets = 1;
    WifiNative.BucketSettings bucketSettings = new WifiNative.BucketSettings();
    bucketSettings.bucket = 0;
    bucketSettings.period_ms = 0;
    bucketSettings.report_events = WifiScanner.REPORT_EVENT_AFTER_EACH_SCAN;

    ChannelCollection channels = mChannelHelper.createChannelCollection();
    List<WifiNative.HiddenNetwork> hiddenNetworkList = new ArrayList<>();
    for (RequestInfo<ScanSettings> entry : mPendingScans) {
            settings.scanType = mergeScanTypes(settings.scanType, entry.settings.type);
            settings.enable6GhzRnr = mergeRnrSetting(settings.enable6GhzRnr, entry.settings);
            channels.addChannels(entry.settings);
            for (ScanSettings.HiddenNetwork srcNetwork : entry.settings.hiddenNetworks) {
                    WifiNative.HiddenNetwork hiddenNetwork = new WifiNative.HiddenNetwork();
                    hiddenNetwork.ssid = srcNetwork.ssid;
                    hiddenNetworkList.add(hiddenNetwork);
            }
            if ((entry.settings.reportEvents & WifiScanner.REPORT_EVENT_FULL_SCAN_RESULT)
                            != 0) {
                    bucketSettings.report_events |= WifiScanner.REPORT_EVENT_FULL_SCAN_RESULT;
            }

            if (entry.clientInfo != null) {
                    mWifiMetrics.getScanMetrics().setClientUid(entry.clientInfo.mUid);
            }
            mWifiMetrics.getScanMetrics().setWorkSource(entry.workSource);
    }

    if (hiddenNetworkList.size() > 0) {
            settings.hiddenNetworks = new WifiNative.HiddenNetwork[hiddenNetworkList.size()];
            int numHiddenNetworks = 0;
            for (WifiNative.HiddenNetwork hiddenNetwork : hiddenNetworkList) {
                    settings.hiddenNetworks[numHiddenNetworks++] = hiddenNetwork;
            }
    }

    channels.fillBucketSettings(bucketSettings, Integer.MAX_VALUE);
    settings.buckets = new WifiNative.BucketSettings[] {bucketSettings};

    if (mScannerImplsTracker.startSingleScan(settings)) {
            mWifiMetrics.getScanMetrics().logScanStarted(
                            WifiMetrics.ScanMetrics.SCAN_TYPE_SINGLE);

            // store the active scan settings
            mActiveScanSettings = settings;
            // swap pending and active scan requests
            RequestList<ScanSettings> tmp = mActiveScans;
            mActiveScans = mPendingScans;
            mPendingScans = tmp;
            // make sure that the pending list is clear
            mPendingScans.clear();
            transitionTo(mScanningState);
    } else {
            mWifiMetrics.incrementScanReturnEntry(
                            WifiMetricsProto.WifiLog.SCAN_UNKNOWN, mPendingScans.size());
            mWifiMetrics.getScanMetrics().logScanFailedToStart(
                            WifiMetrics.ScanMetrics.SCAN_TYPE_SINGLE);

            // notify and cancel failed scans
            sendOpFailedToAllAndClear(mPendingScans, WifiScanner.REASON_UNSPECIFIED,
                            "Failed to start single scan");
    }
}
```



