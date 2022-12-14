NR == 1 {prev_channel=$2; start_time=$1; current_address=$4} 
NR > 1 {
  if ($4 == current_address) {
      printf "%f %f %d %d %d %d %s\n" ,$1, $1 - start_time, prev_channel, $2, $3, $6, $4; prev_channel=$2;
  }
  else {
    # first time we've seen this address, consider the first time we see it as 0
    printf "%f %f %d %d %d %d %s\n" ,$1, 0, prev_channel, $2, $3, $6, $4; prev_channel=$2; start_time=$1; current_address=$4;
  }
} 
