#!/bin/bash

# this script captures network traffic from 3 dongles
# this script is run as a cron job (with root privileges) to capture data every
# hour of the day for (currently) 30 minutes. The pcap files are combined and
# converted into a usable text file for analysis.


# first let's get the date and the hour
hour=$(date +%H)
now=$(date +%d_%m_%y)
log=/tmp/mylog.out
CAPTURE_TIME=45
SLEEP_TIME=46


# first capture of the day, prep for the rest of the day
if [[ $hour == "00" ]]; then
  echo "$(date) Creating directories and turning on interfaces" >> $log
  mkdir -p "/home/deinum/sdr/data/pcap/hourly/$now" 
  mkdir -p "/home/deinum/sdr/data/text/hourly/$now"

  ip link set wlx00127b216d36 down
  ip link set wlx00127b216d1e down
  ip link set wlx00127b216d41 down

  iw wlx00127b216d36 set monitor fcsfail
  iw wlx00127b216d1e set monitor fcsfail
  iw wlx00127b216d41 set monitor fcsfail

  ip link set wlx00127b216d36 up
  ip link set wlx00127b216d1e up
  ip link set wlx00127b216d41 up

  iw wlx00127b216d36 set channel 1
  iw wlx00127b216d1e set channel 6
  iw wlx00127b216d41 set channel 11
fi

echo "$(date) Starting scan" >> $log
timeout "$CAPTURE_TIME"m tcpdump -i wlx00127b216d36 type mgt subtype probe-req -w "/home/deinum/sdr/data/channel-1.pcap" &
timeout "$CAPTURE_TIME"m tcpdump -i wlx00127b216d1e type mgt subtype probe-req -w "/home/deinum/sdr/data/channel-6.pcap" &
timeout "$CAPTURE_TIME"m tcpdump -i wlx00127b216d41 type mgt subtype probe-req -w "/home/deinum/sdr/data/channel-11.pcap" &
sleep "$SLEEP_TIME"m

echo "$(date) Scan Finished" >> $log

# combine pcap files into a single file and remove the uneccessary stuff
echo "$(date) Merging PCAP files" >> $log
mergecap -w "/home/deinum/sdr/data/pcap/hourly/$now/sample$hour.pcap" /home/deinum/sdr/data/*.pcap
rm /home/deinum/sdr/data/channel-1.pcap
rm /home/deinum/sdr/data/channel-6.pcap
rm /home/deinum/sdr/data/channel-11.pcap

echo "$(date) Converting PCAP to TEXT" >> $log
/home/deinum/sdr/code/filter.sh "/home/deinum/sdr/data/pcap/hourly/$now/sample$hour.pcap" "/home/deinum/sdr/data/text/hourly/$now/sample$hour.txt" 


echo "$(date) Adding previous channel using AWK" >> $log
cat "/home/deinum/sdr/data/text/hourly/$now/sample$hour.txt" | 
mawk -f "/home/deinum/sdr/code/clean.awk"  > /tmp/clean.txt
mv /tmp/clean.txt "/home/deinum/sdr/data/text/hourly/$now/sample$hour.txt" 
chown -R deinum "/home/deinum/sdr/data/text/hourly/$now/sample$hour.txt"

# last scan of the day
if [[ $hour == "23" ]]; then
  echo "$(date) Turning off interfaces" >> $log
  ip link set wlx00127b216d36 down
  ip link set wlx00127b216d1e down
  ip link set wlx00127b216d41 down
fi

echo "$(date) Done with sample $hour" >> $log

