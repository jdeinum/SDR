# Using the iw Command to Monitor Events
iw is a command line tool that allows us to view and manipulate wireless devices
and their configurations. We can use it to see when scans are requested, as well
as observe frames that pass through the network interface.

# Interesting Commands
The following command prints the timestamp, as well as the event that it
monitored. Running `iw event -t -f` gives us the following output:
```
1651867975.551104: wlp61s0 (phy #0): scan started
1651867977.930725: wlp61s0 (phy #0): scan finished: 2412 2417 2422 ...
1651867995.753880: wlp61s0 (phy #0): scan started
1651867996.988906: wlp61s0 (phy #0): scan finished: 2412 2417 2422 ...
```

Since the device knows that a scan is occurring, there may be a way to dump more
information from the interface. If this is the case, then we may not need to use
sniffers anymore, and can use tcpdump output on the device itself along with the
scan information received from iw.



