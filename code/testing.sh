#!/bin/bash


sudo ip link set wlp0s20f0u1 down

# sudo iw wlp0s20f0u1 set monitor fcsfail
sudo iwconfig wlp0s20f0u1 mode monitor

sudo ip link set wlp0s20f0u1 up

sudo tcpdump -i wlp0s20f0u1 type mgt subtype probe-req -w test.pcap
