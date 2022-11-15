#!/bin/bash

# this script is run through cron each day at midnight using the following
# script
# sudo crontab
# 0 0 * * * /home/deinum/sdr/code/driver.sh

now=$(date +%d_%m_%y)
mkdir "/home/deinum/sdr/data/pcap/hourly/$now"
mkdir "/home/deinum/sdr/data/text/hourly/$now"

for ((i = 0; i < 24; i++)); do
  /home/deinum/sdr/code/main.sh -c 30 -f "/home/deinum/sdr/data/pcap/hourly/$now/sample$i.pcap"
  sleep 30m
done

for ((i = 0; i < 24; i++)); do
  /home/deinum/sdr/code/filter.sh "/home/deinum/sdr/data/pcap/hourly/$now/sample$i.pcap" "/home/deinum/sdr/data/text/hourly/$now/sample$i.txt" 
done
