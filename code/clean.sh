# remove any line that is missing data
# usually this is from the source and destination address being the same
awk -F"\t" '{for(N=1; N<=6; N++) if($N=="") break; else if(N==6) print }' |

# sort by the address and the time
sort -k4,4 -k1,1n |

# now add the previous channel and the time relative to the first packet seen
# from an address
mawk -f /home/deinum/Work/sdr/code/clean.awk





