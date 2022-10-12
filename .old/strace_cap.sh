#! /bin/bash

# outputs strace output to the specified file

FILENAME=${1:-strace.out};


nmap -v -sn 192.168.0.0/24 > /dev/null &
PID=$(ps | grep "nmap" | tr -s ' ' | cut -d ' ' -f 2)
echo "Capturing traffic for process $PID..."
sudo strace -p "$PID" > "$FILENAME" 2>&1 || (echo "killing process $PID" && kill "$PID" 2>/dev/null && exit)
echo "Output saved to $FILENAME"

