SDR Image




# Table of Contents
- [Overview](#overview)
- [Purpose](#purpose)
- [Background](#background)
- [Stages](#stages)
- [Setting up](#setting-up)
- [The Experiment](#the-experiment)
- [Results](#results)
- [Future Work](#future-work)


Overview
Purpose
Background
Stages
Setting up
The Experiment
Results
Future Work

# Overview
When devices (namely phones but realistically anything that uses WiFi) want to
connect to a network, they must first identify which networks are available in
the area as well which of the networks would be the best to connect to. One way
the device can find available networks is by sending out messages that nearby
access points reply to. Our research focus is on determining if the message
pattern for the initiating devices can uniquely identify it in a public
environment.


# Purpose
The primary purpose of this research is for organizations to determine the
number of unique devices in an area. Since most people only carry one device
with them, it can also be used to estimate the number of people in an area.


# Background
This section will cover some background information relative to the project. If
this does not interest you, feel free to skip to the [next](#stages) section. I
am assuming that whomever is reading this is familiar with basic networking
concepts such as IP addressing, MAC addresses, etc.

### The 2.4 GHz Spectrum 
While we will eventually be scanning both the 2.4GHz and the 5GHz channels, we
will focus our attention on the 2.4GHz spectrum for this section. 

![The 2.4GHz Spectrum](./images/two_four.png) 


The main channels in use are the ones that provide non overlapping intervals.
These are shown in the image above by the bold circles on channels 1, 6, and
11.When messages from the 802.11 protocol are sent, they are typically sent on
one of these channels. Most devices will alternate which channels they use to
maximize the chance of being heard (if an AP wasn't listening on 6, it may still
hear the other 2 channels).

Knowing these frequencies allows to set our capturing devices to capture the
correct information.


### Probe Requests
Probe requests are messages sent out by your device when scanning for WiFi
networks. These messages contain many fields, some notable ones being the sender
address, the receiver address (the intended recipient), and supported rates
(speed of the network). If an AP hears the message, and sees that
it is the intended recipient, it replies with a probe response. In the probe
response, the AP attaches information such as name of its WiFi network, what
kind of authentication is required to use it, supported rates, and any extra
features it provides. Therefore, probe requests/responses can be used to relay
information to devices about nearby WiFi networks. When performing the analysis
for this experiment, we use the packet Interarrival times.


![PR](./images/it.png)


The interarrival times can range from a few microseconds to hundreds of seconds
if it is the end of the scan. 





### Android Scanning Patterns
Now that we have a basic understanding of what a scan looks like, we should take
a look into android scanning patterns. The code for android networking is found
[here](https://cs.android.com/android/platform/superproject/+/master:packages/modules/Wifi/).
Many of these files change over time, so I will not link every piece of source
code.


#### Watchdog

The watchdog is a mechanism to look for WiFi networks when the phone is not
currently connected to a WiFi network:

```java
private void watchdogHandler() {
  // Schedule the next timer and start a single scan if we are in disconnected state.
  // Otherwise, the watchdog timer will be scheduled when entering disconnected
  // state.
  if (mWifiState == WIFI_STATE_DISCONNECTED) {
      localLog("start a single scan from watchdogHandler");

      scheduleWatchdogTimer();
      startSingleScan(true, WIFI_WORK_SOURCE);
  }
}
```

So a full band scan is sent every time scheduleWatchdogTimer() is triggered.
Looking at this function, we see that the timer expires `config_wifiPnoWatchdogIntervalMs` 
after setting it. Finding 

```java
public static final int config_wifiPnoWatchdogIntervalMs=0x7f050040;
```

Since we don't access to their RO data, we trust the docs which state that Which
state that this is once every 20 minutes.

#### Periodic Scans

The majority of the scanning comes from the periodic scans set up within
Android.

The handler for the timer is:

```java
// line 1778
private void periodicScanTimerHandler() {
    localLog("periodicScanTimerHandler");

    // Schedule the next timer and start a single scan if screen is on.
    if (mScreenOn) {
        startPeriodicSingleScan();
    }
}
```

The first thing of interest is that the scan only occurs if the screen is on.
The definition for startPeriodicSingleScan() is rather long, so instead of
dumping all of it here, I'll go through it piece by piece and dump the full
definition of the function in the appendix.

```java
long currentTimeStamp = mClock.getElapsedSinceBootMillis();

if (mLastPeriodicSingleScanTimeStamp != RESET_TIME_STAMP) {
    long msSinceLastScan = currentTimeStamp - mLastPeriodicSingleScanTimeStamp;
    if (msSinceLastScan < getScheduledSingleScanIntervalMs(0)) {
        localLog("Last periodic single scan started " + msSinceLastScan
                + "ms ago, defer this new scan request.");
        schedulePeriodicScanTimer(
                getScheduledSingleScanIntervalMs(0) - (int) msSinceLastScan);
        return;
    }
}
```

In the first section, we check if our scan request timer left enough time
between our last scan and the current one. If we didn't leave enough time
between them, we just reschedule this scan to happen once enough time has
occurred. Now the question is what "enough time" is. Inside
`getScheduledSingleScanIntervalMs()` we see the following:

```java
private int getScheduledSingleScanIntervalMs(int index) {
  synchronized (mLock) {
      if (mCurrentSingleScanScheduleSec == null) {
          Log.e(TAG, "Invalid attempt to get schedule interval, Schedule array is null ");

          // Use a default value
          return DEFAULT_SCANNING_SCHEDULE_SEC[0] * 1000;
      }

      if (index >= mCurrentSingleScanScheduleSec.length) {
          index = mCurrentSingleScanScheduleSec.length - 1;
      }
      return getScanIntervalWithPowerSaveMultiplier(
              mCurrentSingleScanScheduleSec[index] * 1000);
  }
}
```

The schedule is guarded by a lock, which makes sense since we want to make sure
we leave the right amount of time between scans. Since the 802.11 protocol
expects scans according to exponential backoff, having a race condition risks
not following the expected procedure.


If a scan schedule has not been provided, then a default value is provided. The
default schedule is defined as:

```java
private static final int[] DEFAULT_SCANNING_SCHEDULE_SEC = {20, 40, 80, 160};
```

Note that these times are in milliseconds, despite the name containing seconds.
Thus, without a specified scan schedule, a scan is expected to occur every 20
seconds. 

If a user defined scanning schedule is provided, then we simply find the entry
to use as our scan interval. If the index is greater than our scan schedule
length, we just return the maximum value. If not, we just use specified index.

Once we have the index, we call `getScanIntervalWithPowerSaveMultiplier()`,
for which the definition is:


```java
private int getScanIntervalWithPowerSaveMultiplier(int interval) {
  if (!mDeviceConfigFacade.isWifiBatterySaverEnabled()) {
      return interval;
  }
  return mPowerManager.isPowerSaveMode()
          ? POWER_SAVE_SCAN_INTERVAL_MULTIPLIER * interval : interval;
}
```

So if power saving mode is enabled, we multiply our interval by a factor of
POWER_SAVE_SCAN_INTERVAL_MULTIPLIER.

```java
private static final int POWER_SAVE_SCAN_INTERVAL_MULTIPLIER = 2;
```

So if power saving mode is enabled, we double our previous scan interval. Now
the question is whether Android uses a custom configuration or if it uses its
default scan schedules. Android has 3 different usable scan schedules, defined
much earlier:

```java
private int[] mConnectedSingleScanScheduleSec;
private int[] mDisconnectedSingleScanScheduleSec;
private int[] mConnectedSingleSavedNetworkSingleScanScheduleSec;
```

One while connected to another network, one while not connected, and one while
connected with only 1 saved network. 

These scanning schedules must be initialized somewhere, so searching for them,
we find the following function:

```java
private int[] initializeScanningSchedule(int state) {
    int[] scheduleSec;

    if (state == WIFI_STATE_CONNECTED) {
        scheduleSec = mContext.getResources().getIntArray(
                R.array.config_wifiConnectedScanIntervalScheduleSec);
    } else if (state == WIFI_STATE_DISCONNECTED) {
        scheduleSec = mContext.getResources().getIntArray(
                R.array.config_wifiDisconnectedScanIntervalScheduleSec);
    } else {
        scheduleSec = null;
    }

    boolean invalidConfig = false;
    if (scheduleSec == null || scheduleSec.length == 0) {
        invalidConfig = true;
    } else {
        for (int val : scheduleSec) {
            if (val <= 0) {
                invalidConfig = true;
                break;
            }
        }
    }
    if (!invalidConfig) {
        return scheduleSec;
    }

    Log.e(TAG, "Configuration for wifi scanning schedule is mis-configured,"
            + "using default schedule");
    return DEFAULT_SCANNING_SCHEDULE_SEC;
}
```

So we can simply look up the configurations, we find that:

```java
public static final int config_wifiBackgroundScanThrottleExceptionList=0x7f010000;
public static final int config_wifiConnectedScanIntervalScheduleSec=0x7f010001;
public static final int config_wifiDisconnectedScanIntervalScheduleSec=0x7f010002;
```

These values are likely just IDs into the resources folder. Searching the
folders for these IDs we get that:

```html
<!-- Array describing scanning schedule in seconds when device is disconnected and screen is on -->
<integer-array translatable="false" name="config_wifiDisconnectedScanIntervalScheduleSec">
    <item>20</item>
    <item>40</item>
    <item>80</item>
    <item>160</item>
</integer-array>

<!-- Array describing scanning schedule in seconds when device is connected and screen is on -->
<integer-array translatable="false" name="config_wifiConnectedScanIntervalScheduleSec">
    <item>20</item>
    <item>40</item>
    <item>80</item>
    <item>160</item>
</integer-array>

<!-- Array describing scanning schedule in seconds when device is connected and screen is on
     and the connected network is the only saved network.
     When this array is set to an empty array, the noraml connected scan schedule defined
     in config_wifiConnectedScanIntervalScheduleSec will be used -->
<integer-array translatable="false" name="config_wifiSingleSavedNetworkConnectedScanIntervalScheduleSec">
</integer-array>
```

Back to our initial `startPeriodicSingleScan()`, we've gotten our scan interval
and now we need to check whether the scan is needed. This is done by checking
one of the following conditions:

1) Network is sufficient
2) Link is good, internet status is acceptable and it is a short time since last
network selection
3) There is active stream such that scan will be likely disruptive

The code for this is:

```java
if (mWifiState == WIFI_STATE_CONNECTED
        && (mNetworkSelector.isNetworkSufficient(wifiInfo)
        || isGoodLinkAndAcceptableInternetAndShortTimeSinceLastNetworkSelection
        || mNetworkSelector.hasActiveStream(wifiInfo))) {
    // If only partial scan is proposed and firmware roaming control is supported,
    // we will not issue any scan because firmware roaming will take care of
    // intra-SSID roam.
    if (mConnectivityHelper.isFirmwareRoamingSupported()) {
        localLog("No partial scan because firmware roaming is supported.");
        isScanNeeded = false;
    } else {
        localLog("No full band scan because current network is sufficient");
        isFullBandScan = false;
    }
}
```
What is considered "sufficient" and "acceptable" is left for now, but can be
explored at a later point.

---

Now we know whether we need the scan or not. If we need the scan, we scan and
then set the timer for the next scan. Otherwise, we just set the timer for the
next scan:


```java
if (isScanNeeded) {
  mLastPeriodicSingleScanTimeStamp = currentTimeStamp;

  if (mWifiState == WIFI_STATE_DISCONNECTED
          && mInitialScanState == INITIAL_SCAN_STATE_START) {
      startSingleScan(false, WIFI_WORK_SOURCE);

      // Note, initial partial scan may fail due to lack of channel history
      // Hence, we verify state before changing to AWIATING_RESPONSE
      if (mInitialScanState == INITIAL_SCAN_STATE_START) {
          setInitialScanState(INITIAL_SCAN_STATE_AWAITING_RESPONSE);
          mWifiMetrics.incrementInitialPartialScanCount();
      }
  } else {
      startSingleScan(isFullBandScan, WIFI_WORK_SOURCE);
  }
  schedulePeriodicScanTimer(
          getScheduledSingleScanIntervalMs(mCurrentSingleScanScheduleIndex));

  // Set up the next scan interval in an exponential backoff fashion.
  mCurrentSingleScanScheduleIndex++;
} else {
  // Since we already skipped this scan, keep the same scan interval for next scan.
  schedulePeriodicScanTimer(
          getScheduledSingleScanIntervalMs(mCurrentSingleScanScheduleIndex));
}
```

Initial scans are the first scan after WiFi has been enabled or turning on the
screen when disconnected. Since Android has sensors in their phones that detect
movement, initial scans may occur without any user interaction.



---
#### What Happens When a Scan Fails?

One thing we should be interested in is what happens if a scan fails, and what
it even means when a scan fails? The function that schedules retries is:

```
private void scheduleDelayedSingleScan(boolean isFullBandScan) {
    localLog("scheduleDelayedSingleScan");

    RestartSingleScanListener restartSingleScanListener =
            new RestartSingleScanListener(isFullBandScan);
    mAlarmManager.set(AlarmManager.ELAPSED_REALTIME_WAKEUP,
                        mClock.getElapsedSinceBootMillis() + RESTART_SCAN_DELAY_MS,
                        RESTART_SINGLE_SCAN_TIMER_TAG,
                        restartSingleScanListener, mEventHandler);
}
```

So we wait `RESTART_SCAN_DELAY_MS` before scanning again, which is set here:

```
private static final int RESTART_SCAN_DELAY_MS = 2 * 1000; // 2 seconds
```

Another note is that we'll only retry up to MAX_SCAN_RESTART_ALLOWED times,
which is set here:

```    
public static final int MAX_SCAN_RESTART_ALLOWED = 5;
```

So we try the scan every 2 seconds up to 5 times.


The scanning procedure can be represented as a finite state machine, shown here:

INSERT IMAGE


# Stages
The experiment will be broken up into several stages:

1. Determining the effectiveness of our measurements in isolation (i.e. can we
   should that the probing behavior for a device is consistent in isolation?)

2. Determining accuracy of our system in a public environment with enough
   noise (such as a coffee shop)

3. Determining the effectiveness of our research in a potential use case (i.e a
   park)

The rest of the document will focus on stage 1.


# Setting Up
Given that this experiment is very sensitive to other network noise, the first
step is finding a suitably quiet location to conduct the experiment. This step
is optional but may improve results.





# The Experiment
An Android device will be placed somewhere in isolation 



# Results



# Future Work



# Sources
