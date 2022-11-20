#!/bin/bash



# Phone 1, No MAC randomization
./clean.sh ../data/pcap/sample1.pcap > ../data/text/sample1.txt
./clean.sh ../data/pcap/sample2.pcap > ../data/text/sample2.txt
./clean.sh ../data/pcap/sample3.pcap > ../data/text/sample3.txt
./clean.sh ../data/pcap/sample4.pcap > ../data/text/sample4.txt
./clean.sh ../data/pcap/sample5.pcap > ../data/text/sample5.txt

./clean_unknown.sh ../data/pcap/sample6.pcap > ../data/text/sample6.txt
./clean_unknown.sh ../data/pcap/sample7.pcap > ../data/text/sample7.txt
./clean_unknown.sh ../data/pcap/sample8.pcap > ../data/text/sample8.txt
./clean_unknown.sh ../data/pcap/sample9.pcap > ../data/text/sample9.txt
./clean_unknown.sh ../data/pcap/sample10.pcap > ../data/text/sample10.txt

./clean_unknown.sh ../data/pcap/sample11.pcap > ../data/text/sample11.txt
./clean_unknown.sh ../data/pcap/sample12.pcap > ../data/text/sample12.txt
./clean_unknown.sh ../data/pcap/sample13.pcap > ../data/text/sample13.txt
./clean_unknown.sh ../data/pcap/sample14.pcap > ../data/text/sample14.txt
./clean_unknown.sh ../data/pcap/sample15.pcap > ../data/text/sample15.txt

