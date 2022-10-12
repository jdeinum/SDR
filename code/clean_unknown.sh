#!/bin/bash

tcpdump -r $1 -tt --time-stamp-precision=nano |
awk 
'{if ($4 ~ /bad-fcs/) {print $1" "$7" " $12} else if  ($4 ~ /bad-fcs/ && $7 ~ /MCS/) {print $1" "$5" "$18} else if ($4 ~ /short/) {print $1" "$9" "$14} else {print $1" "$6" "$11}}' |
awk ' {gsub(2412,1); gsub(2437,6); gsub(2462,11); print $0 }' |
tr -d '-' |
tr -d '[dBm]' |
tail -n+2 > $2


