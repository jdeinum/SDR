# SDR

## The Goal
Use the SDR to confirm that the times reports by the kernel on packet arrival
are accurate. 

## Setting Up The SDR
The SDR should be setup and ready to go if you are in the lab. One thing to note
is that the SDR should be turned on before the server, or else it won't be
recognized by `gnuradio companion` and other tools in that family. 


should make the device show up without needing to reboot. If all is well, you
should be able to run `uhd_find_devices` and see the SDR come up as a device.
The python script for capturing the signals is already in the same directory as
the shell script that manages the capturing of both sources


## Capturing Samples
Now that the SDR is ready to capture samples, we need to find a way to start
capturing that ensures that:

1. We capture at least 1 probe sequence without capturing 20000GB of samples 
2. We start capturing data from tcpdump and the SDR simultaneously


#### Capturing >0 Probe Sequences:
Because the SDR is using such a high sample rate, we need a way to determine
when a scan is started on the Android and communicate that to a server. The tool
of interest here is iw, which when run as:

`iw event -f -t`


Here are the options for getting the information we need:

1. Change the source code of iw to enable communication with the server
   using adb.

2. Pipe the output of `iw event -f -t` into a file, and use a tool like ripgrep
   to determine if the string `"scan started"` is in the file. 



Option 2 seems simpler to implement , so it's the first one we'll try. If it's
been started, we clear the file and start the SDR. We don't expect to device to
scan multiple times per second so it is very unlikely we'll run into race
conditions between deleting and adding data to the file. If this becomes an
issue (not detecting a scan starting), we can deal with it then.

Our capture then looks like the following:

```c
while true {
  
  adb pull remote_location ./file

  if "scan started" in file {
    startSDR()
    echo "" > file
    adb push file remote_location
    break // we break if we only want 1 capture, otherwise keep going
  }
  sleep(0.5) // sleep half a second, can tune this 
}
```


The process on Android is rather simple, since it is just running:

`iw event -t -f > /data/some_file.txt`. 




#### Capturing Simultaneously:
Capturing simultaneously is rather difficult to achieve. Using a bash
script allows the commands to be executed nearly simultaeously but it does not
guarantee that we start capturing at the same time. gnuradio / tcpdump have some
startup delays that are rather difficult to predict. Instead of trying to ensure
they start at the same time, we let them start whenever and then send a hand
crafted request that we can identify both on the SDR output (through signal
strength) as well as tcpdump (through packet characteristics). Doing so allows
us to ignore the startup differences and instead just lets us match the two data
sets afterwards.

To create a custom scan, we'll use iw scan:

```bash
dev <devname> scan [-u] [freq <freq>*] [duration <dur>] [ies <hex as 00:11:..>] [meshid <meshid>] [lowpri,flush,ap-force,duration-mandatory] [randomise[=<addr>/<mask>]] [ssid <ssid>*|passive]
      Scan on the given frequencies and probe for the given SSIDs
      (or wildcard if not given) unless passive scanning is requested.
      If -u is specified print unknown data in the scan results.
      Specified (vendor) IEs must be well-formed.
```


So something like:

```bash
scan ssid "my_man_yannis" 
```

If we have this device close to the SDR with its interface turned off, we should
be able to line up the data sets.


## Analyzing Samples
Once we have both the tcpdump output and the SDR output, we need to be able to
extract the information we want from them. The tcpdump output is already nice
formatted (timestamps, plus optional channels), so we'll focus on SDR output. If
we record for say, 5 seconds, we'll have 5 * 50000000 = 250000000 samples. This
many points makes it hard to extract valuable information from. To improve its
usefulness, we group N samples together, and take their median to use as a
point. To find a reasonable sample group size, we must consider how many samples
are taken on average during the transmission of one probe request. Inspecting a
packet with the average size (180 bytes) in wireshark, we can see that
transmission time is $1384\mu$s. Because we are sampling at 50MHz, the number of
samples we expect is:

$$
\begin{align*}
	\text{num samples} &= \text{transmission\_time * sample\_rate} \\
				 &= \frac{1384\mu s}{1000000 \frac{\mu s}{s}}\; 50000000 \frac{samples}{sec}\\
				 &= 69200\; \text{samples}
\end{align*}
$$


So if we group together 30000, we can represent the group by its median and
still see jumps in power. We do this using a binary written in rust.


Once we have the modified data set, we can graph it using R/Python/gnuplot and
determine the spikes of power.
