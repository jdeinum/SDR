# Examining the Linux Kernel Source Code

## The Goal
We want to find how the Linux kernel:

1) Chooses which channels to scan, and how it orders them
2) Interacts with the network devices, and identify a pattern unique to each
device.

## Downloading the Source Code
First, we need to actually download the source code from
[github](https://github.com/torvalds/linux).


## Finding Files of Interest
Being over 5GB, working through each file isn't an option. Instead we use tools
such as ripgrep to find files that contain keyword of interest. My chosen
keywords of interest were:

Running `rg "active scan"` yields a match in `net/mac80211/scan.c`, which seems
promising. Inside this file, we have a load of useful functions and structs.
Some of the functions that look promising are:


```c
// 
void ieee80211_scan_rx()

// 
ieee80211_prepare_scan_chandef()

// 
static void __ieee80211_scan_completed()

//
static bool __ieee80211_can_leave_ch()

//
static void ieee80211_send_scan_probe_req()

//
static void ieee80211_scan_state_send_probe()

// 
static int __ieee80211_start_scan()

//
static unsigned long ieee80211_scan_get_channel_time()

// 
static void ieee80211_scan_state_decision()

//
static void ieee80211_scan_state_set_channel()

//
static void ieee80211_scan_state_set_channel()

// 
static void ieee80211_scan_state_set_channel()
```

Let's go over each of these in depth and see what they do.


### void ieee80211_scan_rx()

The full signature is:
```c
void ieee80211_scan_rx(struct ieee80211_local *local, struct sk_buff *skb)
```

This function monitors incoming packets, and checks if they are packets of
interest. More specifically, it takes specific action on probe responses and
beacon frames that are either intended for this specific device or the broadcast
device.


### ieee80211_prepare_scan_chandef()

The full signature is:
```c
static void ieee80211_prepare_scan_chandef(struct cfg80211_chan_def *chandef, 
		enum nl80211_bss_scan_width scan_width)
```

This functions role is to set the correct channel width.


### static void __ieee80211_scan_completed()

The full signature is:
```c
static void __ieee80211_scan_completed(struct ieee80211_hw *hw, bool aborted)
```

This functions role is to do some housekeeping in terms of figuring out if the
scan was completed successfully, or aborted. It also notifies the MLME that the
scan was completed.

### static bool __ieee80211_can_leave_ch()

The full signature is: 

```c
static bool __ieee80211_can_leave_ch(struct ieee80211_sub_if_data *sdata)
```

This functions role is to check whether or not we can leave the current channel.
It does so through a series of checks, as well as a set of mutexes. It is a
possibility that acquiring the lock may be a source of delay in between two
probe requests scanning different channels. The actual cost is unknown however,
although I am fairly sure they are spin locks, offering slightly lower latency.

### static void ieee80211_send_scan_probe_req()

The full signature is: 

```c
static void ieee80211_send_scan_probe_req(struct ieee80211_sub_if_data *sdata,
					  const u8 *src, const u8 *dst,
					  const u8 *ssid, size_t ssid_len,
					  const u8 *ie, size_t ie_len,
					  u32 ratemask, u32 flags, u32 tx_flags,
					  struct ieee80211_channel *channel)
```

This functions role is to build and send a probe request given the required
information (mostly in the signature). It also randomizes the sequence number if
desired.

### static void ieee80211_scan_state_send_probe()

The full signature is:

```c
static void ieee80211_scan_state_send_probe(struct ieee80211_local *local,
					    unsigned long *next_delay)
```

We can immediately note that the delay is passed in, so we may wish to see where
this function is called from to find the source of the delay. First we'll take a
look at what the function does.

First, it tries a acquire a lock to access the medium. This is followed by the
following piece of code:

```c
for (i = 0; i < scan_req->n_ssids; i++)
	ieee80211_send_scan_probe_req(
		sdata, local->scan_addr, scan_req->bssid,
		scan_req->ssids[i].ssid, scan_req->ssids[i].ssid_len,
		scan_req->ie, scan_req->ie_len,
		scan_req->rates[band], flags,
		tx_flags, local->hw.conf.chandef.chan);
```

So for each SSID, we send a probe request without delay. Since the devices we
are interested in will likely be sending purely to the broadcast address, this
section of code shouldn't have an impact on the delay in between probe requests.
Instead, we are more interested in the code that follows immediately after:

```c
/*
 * After sending probe requests, wait for probe responses
 * on the channel.
 */
*next_delay = IEEE80211_CHANNEL_TIME;
local->next_scan_state = SCAN_DECISION;
```

We set the delay to be the 802.11 channel time, which is is defined as:
```c
#define IEEE80211_CHANNEL_TIME (HZ / 33)
```

Which seems that it changes depending on what frequency we are broadcasting.
Interesting. Once it waits out the delay, it decides what to do based on if it
received any probe responses. We set the scan state to SCAN_DECISION, which is
defined as: 

```c
SCAN_DECISION: Main entry point to the scan state machine, this state determines
if we should keep on scanning or switch back to the operating channel 
```

We also see the definition of SCAN_SET_CHANNEL:

```c
SCAN_SET_CHANNEL: Set the next channel to be scanned
```

We'll explore this later when we look at `ieee80211_scan_state_set_channel()`


### static int __ieee80211_start_scan()

The full signature is: 

```c
static int __ieee80211_start_scan(struct ieee80211_sub_if_data *sdata,
				  struct cfg80211_scan_request *req)
```

This functions role is to find all of the details associated with the scan
(hardware vs software), determining if it's ok to scan, ...

Many of the details associated with the request itself are passed in, however we
do wait CHANNEL_TIME again before processing any results.









### static unsigned long ieee80211_scan_get_channel_time()

### static void ieee80211_scan_state_decision()

### static void ieee80211_scan_state_set_channel()










