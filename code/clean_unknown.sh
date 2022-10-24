#!/bin/bash

tcpdump -r $1 -tt --time-stamp-precision=nano |
mawk -f extract.awk |
tail -n+2 
