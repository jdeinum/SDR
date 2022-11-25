#!/bin/bash

tshark -r $1 -T fields \
  -e frame.time_epoch \
  -e wlan_radio.frequency \
  -e wlan_radio.signal_dbm \
  -e wlan.ta \
  -e wlan.ra \
  -e wlan.seq > $2
