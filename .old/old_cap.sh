#! /bin/bash
shopt -s failglob



# check arguments
if (($# < 2 ))
then 
	printf "%b" "usage: ./run.sh output_dir name1"
	exit
fi



# configure our measurements
names=($2);
num_samples=1; # only 1 sample per combination
measure_time=10;





# create the directory if it doesn't exist
mkdir $1


# disable all of the monitor interfaces
sudo ip link set wlp0s20f0u1u1 down;
sudo ip link set wlp0s20f0u1u2 down;
sudo ip link set wlp0s20f0u1u3 down;

# set each device to monitor mode
sudo iw wlp0s20f0u1u1 set monitor fcsfail;
sudo iw wlp0s20f0u1u2 set monitor fcsfail;
sudo iw wlp0s20f0u1u3 set monitor fcsfail;

# enable each device again
sudo ip link set wlp0s20f0u1u1 up;
sudo ip link set wlp0s20f0u1u2 up;
sudo ip link set wlp0s20f0u1u3 up;

# set the correct channel for each device
sudo iw wlp0s20f0u1u1 set channel 1
sudo iw wlp0s20f0u1u2 set channel 6
sudo iw wlp0s20f0u1u3 set channel 11


# capture
for name in ${names[@]};
do
	# create the directory
	mkdir "$1/$name"


	# get data from all 3 dongles on the specififed channel
	sudo tcpdump -i wlp0s20f0u1u1 type mgt subtype probe-req -w "$1/$name/channel-1".pcap 2> /dev/null &
	sudo tcpdump -i wlp0s20f0u1u2 type mgt subtype probe-req -w "$1/$name/channel-6".pcap 2> /dev/null &
	sudo tcpdump -i wlp0s20f0u1u2 type mgt subtype probe-req -w "$1/$name/channel-11".pcap 2> /dev/null &

	# start the capture on the pluto sdr
	python3 pluto.py "$1/$name/$name.sdr" & 

	sleep "$measure_time"m; 
	pid=(`pidof tcpdump`)
	for id in ${pid[@]};
	do
		sudo kill -SIGINT $id
	done

	# merge all of the pcaps into one
	mergecap -w "$1/$name/$name.pcap" "$1/$name/"*.pcap

	# write the time stamps to a file
	tcpdump -r  "$1/$name/$name.pcap" -tt --time-stamp-precision=nano  2> /dev/null |
	awk 'NR == 1{old = $1; old_c = $4; next} 
		{print $1 - old, old_c, $4; old = $1; old_c = $4; }' |
	awk ' {gsub(2412,1); gsub(2437,6); gsub(2462,11); print $0 }' |
	tail -n +2 > "$1/$name".txt

	# convert the complex numbers into a nicer format
	./con "$1/$name/$name.sdr";
	rm "$1/$name/$name.sdr";
	
	
	# wait for the user to hit enter to confirm they made the required change
	read -p "Hit enter once you see we're finished"


done




# turn off all of the interfaces
sudo ip link set wlp0s20f0u1u1 down;
sudo ip link set wlp0s20f0u1u2 down;
sudo ip link set wlp0s20f0u1u3 down;




