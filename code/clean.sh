#!/bin/bash

# extract only our probe requests with proper time
tcpdump -r $1 ether host e8:50:8b:43:b1:20 -tt --time-stamp-precision=nano |
mawk -f extract.awk |
<<<<<<< HEAD
tail -n+2
=======
tail -n+2 
>>>>>>> refs/remotes/origin/master


