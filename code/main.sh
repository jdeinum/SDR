#!/bin/bash

# ----------------------------------------------------------------------------
# parse input

# Defaults
OFILE="cleaned.txt";
MIN_ARGS=0;
MAX_ARGS=4;
CAPTURE_TIME=10;
ANALYZE=false;

# Did we supply the right number of args?
if [ $# -lt "$MIN_ARGS" -o $# -gt "$MAX_ARGS" ]; then
    printf "Usage: %s: [-f ofile] [-c capture_time_mins] [-a analyze]\n" ${0##*/} >&2;
    exit -1;
fi

# Parsing what we got
while getopts 'f:c:' OPTION
do
    case "$OPTION" in
        f) OFILE="$OPTARG"
            ;;
        c) CAPTURE_TIME="$OPTARG"
            ;;
        a) ANALYZE=true;
    esac
done
shift $(($OPTIND - 1))



# -----------------------------------------------------------------------------
# Check ADB status
# ADB_NUM_DEV=`adb devices -l | wc -l`
# if [[ $ADB_NUM_DEV < 3 ]]; then
#     printf "There isnt a phone that adb can connect to!\n"
#     exit 1
# fi


# -----------------------------------------------------------------------------
# Check iw status
# if [[ `adb shell iw | grep "command not found"` ]]; then
#     printf "iw is not installed correctly on the device! Ensure it is installed
#     and on the path\n"
#     exit 2
# fi
#

# -----------------------------------------------------------------------------
# Prepare Capture

# disable all of the monitor interfaces
sudo ip link set wlx00127b216d36 down
sudo ip link set wlx00127b216d1e down
sudo ip link set wlx00127b216d41 down

# set each device to monitor mode
sudo iw wlx00127b216d36 set monitor fcsfail
sudo iw wlx00127b216d1e set monitor fcsfail
sudo iw wlx00127b216d41 set monitor fcsfail

# enable each device again
sudo ip link set wlx00127b216d36 up
sudo ip link set wlx00127b216d1e up
sudo ip link set wlx00127b216d41 up

# set the correct channel for each device
sudo iw wlx00127b216d36 set channel 1
sudo iw wlx00127b216d1e set channel 6
sudo iw wlx00127b216d41 set channel 11

# -----------------------------------------------------------------------------
# SCANNING

# Start tcpdump
sudo tcpdump -i wlx00127b216d36 type mgt subtype probe-req -w "/tmp/channel-1.pcap" 2> /dev/null &
sudo tcpdump -i wlx00127b216d1e type mgt subtype probe-req -w "/tmp/channel-6.pcap" 2> /dev/null &
sudo tcpdump -i wlx00127b216d41 type mgt subtype probe-req -w "/tmp/channel-11.pcap" 2> /dev/null &

# kill after desired time
sleep "$CAPTURE_TIME"m;
pid=(`pidof tcpdump`)
for id in ${pid[@]};
do
    sudo kill -SIGINT $id
done


# -----------------------------------------------------------------------------
# CLEAN

# combine pcap files into a single file and remove the uneccessary stuff
mergecap -w $OFILE /tmp/channel-1.pcap /tmp/channel-6.pcap /tmp/channel-11.pcap

sudo ip link set wlx00127b216d36 down
sudo ip link set wlx00127b216d1e down
sudo ip link set wlx00127b216d41 down
