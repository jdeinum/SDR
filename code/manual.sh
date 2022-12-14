#!/bin/bash

for ((day = 0; day < 23; day++)); do
    for ((i = 0; i < 10; i++)); do
        /home/deinum/Work/sdr/code/filter.sh "/home/deinum/Work/sdr/data/pcap/hourly/0$day_12_22/sample0$i.pcap" "/home/deinum/Work/sdr/data/text/hourly/0'$day'_12_22/sample0$i.txt"
        # cat "/home/deinum/Work/sdr/data/text/hourly/$day_12_22/sample0$i.txt" |
        # mv /tmp/clean.txt "/home/deinum/Work/sdr/data/text/hourly/$day_12_22/sample0$i.txt"
    done
done
