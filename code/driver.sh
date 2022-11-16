#!/bin/bash

# this script is run through cron each day at midnight using the following
# script
# sudo crontab
# 0 0 * * * /home/deinum/sdr/code/driver.sh

now=$(date +%d_%m_%y)
echo $now >> /tmp/myout.log
mkdir -p "/home/deinum/sdr/data/pcap/hourly/$now" 2>/tmp/myout.log
mkdir -p "/home/deinum/sdr/data/text/hourly/$now" 2>/tmp/myout.log

for ((i = 0; i < 24; i++)); do
  /home/deinum/sdr/code/main.sh -c 1 -f "/home/deinum/sdr/data/pcap/hourly/$now/sample$i.pcap" 2>/tmp/myout.log
  echo "Done sample $i" >> /tmp/myout.log
  sleep 30m
done

for ((i = 0; i < 24; i++)); do
  /home/deinum/sdr/code/filter.sh "/home/deinum/sdr/data/pcap/hourly/$now/sample$i.pcap" "/home/deinum/sdr/data/text/hourly/$now/sample$i.txt" 
done
