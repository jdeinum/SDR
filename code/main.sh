#!/bin/bash



# ----------------------------------------------------------------------------
# parse input

# Defaults
OFILE="cleaned.txt";
CAPTURE_TIME=30;

# Parsing what we got
while getopts 'f:c:' OPTION
do
    case "$OPTION" in
        f) OFILE="$OPTARG"
            ;;
        c) CAPTURE_TIME="$OPTARG"
            ;;
    esac
done
shift $(($OPTIND - 1))





# disable all of the monitor interfaces
ip link set wlx00127b216d36 down
ip link set wlx00127b216d1e down
ip link set wlx00127b216d41 down

# set each device to monitor mode
iw wlx00127b216d36 set monitor fcsfail
iw wlx00127b216d1e set monitor fcsfail
iw wlx00127b216d41 set monitor fcsfail

# enable each device again
ip link set wlx00127b216d36 up
ip link set wlx00127b216d1e up
ip link set wlx00127b216d41 up

# set the correct channel for each device
iw wlx00127b216d36 set channel 1
iw wlx00127b216d1e set channel 6
iw wlx00127b216d41 set channel 11

# -----------------------------------------------------------------------------
# SCANNING

# Start tcpdump
timeout "$CAPTURE_TIME"m tcpdump -i wlx00127b216d36 type mgt subtype probe-req -w "/home/deinum/sdr/data/channel-1.pcap" &
timeout "$CAPTURE_TIME"m tcpdump -i wlx00127b216d1e type mgt subtype probe-req -w "/home/deinum/sdr/data/channel-6.pcap" &
timeout "$CAPTURE_TIME"m tcpdump -i wlx00127b216d41 type mgt subtype probe-req -w "/home/deinum/sdr/data/channel-11.pcap" &


# -----------------------------------------------------------------------------
# CLEAN

# combine pcap files into a single file and remove the uneccessary stuff
mergecap -w $OFILE /home/deinum/sdr/data/*.pcap
rm /home/deinum/sdr/data/*.pcap

ip link set wlx00127b216d36 down
ip link set wlx00127b216d1e down
ip link set wlx00127b216d41 down
