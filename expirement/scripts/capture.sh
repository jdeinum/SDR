#!/bin/bash

# Handles capturing traffic on the SDR as well as tcpdump
#
# TODO: Setup the handcrafted scan (after turning off the interface)
#       This means we need an extra network interface just to scan





#------------------------------------------------------------------------------
# HANDLE ARGS

# Defaults
OFILE="out.txt"
MIN_ARGS=0
MAX_ARGS=4
CAPTURE_TIME=60


# Did we supply enough args?
if [ $# -lt "$MIN_ARGS" -o $# -gt "$MAX_ARGS" ]; then
  printf "Usage: %s: [-f filename] [-c capture_time] [-p sdr_script]\n" ${0##*/} >&2
fi


# Parsing what we got 
while getopts 'f:c:' OPTION 
do
  case "$OPTION" in
    f) OFILE="$OPTARG" 
      ;;
    c) CAPTURE_TIME="$OPTARG"
      ;;
    p) SDR_SCRIPT="$OPTARG"
      ;;
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
# SCANNING SETUP


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

# turn off the interface we use for the synchonization



# -----------------------------------------------------------------------------
# SCANNING

# Start tcpdump
sudo tcpdump -i wlp0s20f0u1u1 type mgt subtype probe-req -w "channel-1".pcap 2> /dev/null &
sudo tcpdump -i wlp0s20f0u1u2 type mgt subtype probe-req -w "channel-6".pcap 2> /dev/null &
sudo tcpdump -i wlp0s20f0u1u2 type mgt subtype probe-req -w "channel-11".pcap 2> /dev/null &



# -----------------------------------------------------------------------------
# SDR

# Check if the SDR script they passed in exists
if [ ! -f "$SDR_SCRIPT" ]; then
  printf "$SDR_SCRIPT does not exist!"
  exit(1)
fi

# Start iw on the Android Device
adb shell "iw event -f -t > /data/testing_file.txt" &
ANDROID=$(`pidof adb`)


# Polling service
adb pull /data/testing_file.txt ./testing_file.txt
while [[ true  ]]; do
  if grep -q "scan started" ""; then
    
    # scan has started so we want to start capturing SDR output
    break
  fi
  
  # might miss a part of the capture but i think thats ok
  # Since in theory we only need 2 captures
  sleep(0.5)
done



# Capture probe sequence with the SDR
# The script uses a timer to only capture for a few seconds
# We dont actually create the script, instead gnuradio produces it for us from the 
# flow graph we use
python3 sdr_capture.py &

# -----------------------------------------------------------------------------
# SYNCHRONIZE

# Send our custom probe request




# send our handcrafted scan so that we can synchronize the SDR / tcpdump output





# wait 60 seconds and then kill everything
sleep "$CAPTURE_TIME"m; 
pid=(`pidof tcpdump`)
for id in ${pid[@]};
do
  sudo kill -SIGINT $id
done
sudo kill -SIGINT  $ANDROID



# merge all of the pcaps into a single one
mergecap -w "combined.pcap" *.pcap


# write the time stamps to a file
tcpdump -r  combined.pcap -tt --time-stamp-precision=nano  2> /dev/null |
awk 'NR == 1{old = $1; old_c = $4; next} 
  {print $1 - old, old_c, $4; old = $1; old_c = $4; }' |
awk ' {gsub(2412,1); gsub(2437,6); gsub(2462,11); print $0 }' |
tail -n + 2 > timestamps.txt



# extract the power values from the file
../bin/powers path_to_file > powers.txt


# group the powers together for nicer analysis
../bin/convert powers.txt > grouped_.txt
rm powers.txt








































