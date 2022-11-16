#!/bin/bash

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
