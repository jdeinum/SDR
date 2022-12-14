#!/bin/bash

for ((day = 1; day < 14; day++)); do
    for ((i = 0; i < 23; i++)); do
        echo "/home/deinum/Work/sdr/data/pcap/hourly/`printf %02d $day`_12_22/sample`printf %02d $i`.pcap" 
        /home/deinum/Work/sdr/code/filter.sh "/home/deinum/Work/sdr/data/pcap/hourly/`printf %02d $day`_12_22/sample`printf %02d $i`.pcap" |
        /home/deinum/Work/sdr/code/clean.sh > "/home/deinum/Work/sdr/data/text/hourly/`printf %02d $day`_12_22/sample`printf %02d $i`.txt"
        chown deinum:deinum "/home/deinum/Work/sdr/data/text/hourly/`printf %02d $day`_12_22/sample`printf %02d $i`.txt"
    done
done

