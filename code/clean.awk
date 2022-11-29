NR == 1 {prev_channel=$2; start_time=$1} 
NR > 1 {printf "%f %f %d %d %d %d %s\n" ,$1, $1 - start_time, prev_channel, $2, $3, $6, $4; prev_channel=$2}


