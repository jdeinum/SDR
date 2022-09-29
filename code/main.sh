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
ADB_NUM_DEV=`adb devices -l | wc -l`
if [[ $ADB_NUM_DEV < 3 ]]; then
    printf "There isnt a phone that adb can connect to!\n"
    exit 1
fi


# -----------------------------------------------------------------------------
# Check iw status
if [[ `adb shell iw | grep "command not found"` ]]; then
    printf "iw is not installed correctly on the device! Ensure it is installed
    and on the path\n"
    exit 2
fi


# -----------------------------------------------------------------------------
# Prepare Capture

# disable all of the monitor interfaces
sudo ip link set wlp0s20f0u1u1 down
sudo ip link set wlp0s20f0u1u2 down
sudo ip link set wlp0s20f0u1u3 down

# set each device to monitor mode
sudo iw wlp0s20f0u1u1 set monitor fcsfail
sudo iw wlp0s20f0u1u2 set monitor fcsfail
sudo iw wlp0s20f0u1u3 set monitor fcsfail

# enable each device again
sudo ip link set wlp0s20f0u1u1 up
sudo ip link set wlp0s20f0u1u2 up
sudo ip link set wlp0s20f0u1u3 up

# set the correct channel for each device
sudo iw wlp0s20f0u1u1 set channel 1
sudo iw wlp0s20f0u1u2 set channel 6
sudo iw wlp0s20f0u1u3 set channel 11

# -----------------------------------------------------------------------------
# SCANNING

# Start tcpdump
sudo tcpdump -i wlp0s20f0u1u1 type mgt subtype probe-req -w "channel-1".pcap 2> /dev/null &
sudo tcpdump -i wlp0s20f0u1u2 type mgt subtype probe-req -w "channel-6".pcap 2> /dev/null &
sudo tcpdump -i wlp0s20f0u1u2 type mgt subtype probe-req -w "channel-11".pcap 2> /dev/null &

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
mergecap -w "combined.pcap" *.pcap && rm channel*.pcap

# write the time stamps to a file
tcpdump -r  combined.pcap -tt --time-stamp-precision=nano  2> /dev/null |
awk 'NR == 1{old = $1; old_c = $4; next}
{print $1 - old, old_c, $4; old = $1; old_c = $4; }' |
awk ' {gsub(2412,1); gsub(2437,6); gsub(2462,11); print $0 }' |
tail -n + 2 > cleaned.txt
rm combined.pcap;


# run analysis if desired
if [[ $ANALYZE ]]; then
    python3 analyze.py cleaned.txt
fi
