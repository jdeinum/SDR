#!/bin/bash

# extract only our probe requests with proper time
tcpdump -r $1 ether host e8:50:8b:43:b1:20 -tt --time-stamp-precision=nano |
mawk -f extract.awk |
tail -n+2


