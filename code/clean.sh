# remove any line that is missing data
# usually this is from the source and destination address being the same
awk -F"\t" '{for(N=1; N<=6; N++) if($N=="") break; else if(N==6) print }'
