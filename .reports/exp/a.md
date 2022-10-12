# Capturing Data

There are 3 capture processes in our experiment:

1. The Network Capture Cards
2. The SDR 
3. The output of the Android device (tentative)


## Network Cards
The network interfaces are used to capture packets from the target device. There
are 3 interfaces set to scan channels 1,6,11 respectfully. The target device is
placed right beside the 3 capture interfaces so there should be no issue with
missing packets. Additional noise will be filtered out using the standard suite
of tools (wireshark / tshark / tcpdump ... etc).

Each packet capture will be prepared by extracting the time of the packet arrival
time, and the channel it was sent on into a single line.


## SDR 
The SDR is used confirm the arrival times reported by the network interfaces. We
must capture the arrival of several packets to confirm that the timings
reported are correct. The SDR captures about 50 million samples per second, so
we can only capture for a short period to limit disk usage. 

The alternative is using something like [RFtap](https://rftap.github.io/). This
would allow us to get RF information about every packet in the capture.
Unfortunately, RFtap has not been maintained and is only compatible with older
versions of gnuradio. If I find a configuration of gnuradio and all of its
sub-modules that would work, then RFtap is the way to go.

## Android Output 
We can use the output from `iw event -f -t ` to determine when a scan has been
started:

```
1664469857.395268: wlp61s0 (phy #0): scan started
1664469861.321621: wlp61s0 (phy #0): scan finished: 2412 2417 2422 2427 2432 ...
```

Not only is this helpful for giving a high level overview of when a scan is
started, it also allows us to start an SDR scan that has a high likelihood of
seeing several packets.

Since this is information we do not have access to in the field, we'll only use
it for testing purposes. One thing to note is that android removes many
functionalities from its Linux subsystem, so sometimes tools must be built and
placed on the device.

## Combining the Data
This section assumes that we are not using RFtap to capture RF information. If
RFtap is used, we can just confirm times directly in Wireshark using `rftap.time`
field.

We need some way to synchronize the SDR output with the packet capture. One way
to approach this would be to find the periodic behavior in the SDR output and
line it up with the nearest packet capture (or do some sort of best fit). Since
the SDR is right beside the target device, its packets should should out since
its power is much greater relative to other nearby devices. 

One thing to note is that the SDR output is only used to ensure our kernel is
reporting reasonable times for packet arrivals. 

## Analyzing the Output
Assuming the samples are reasonable (not too much difference between time
reported by kernel and the SDR), we can analyze the packet capture to determine
the packet inter-arrival times. If our hypothesis is correct, we expect that the
inter-arrival times are consistent across different samples. Remember that there
are several inter-arrival times between packets A and B:

1. A and B are both from the same scan and both are on the same channel
2. A and B are both from the same scan but are sent on different channels
3. A and B are from different scans.

If A and B are from different scans, which channel they occur on likely have
very little impact on time.

We'll create a histogram that groups samples based on A and B. Since our file is
in the following format:

```
12345.6789 11
12345.9876 6
```

We just subtract the time of line n-1 from line n, and put this time in bin
11-6. We'll also insert these entries into a timescale database to visualize and
analyze older data. Additionally, we'll also have separate histograms for
inter-arrival times that are greater than 1 second apart since these times are
so large that they will pollute our analysis. 










