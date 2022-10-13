function sub_channel(freq) {
  if (freq == 2412) 
    return 1

  else if (freq == 2437)
    return 6

  else if (freq == 2462)
    return 11

  else
    return "??"
  }


{for (i = 1 ; i < NF ; i += 1) {
  if (i == 1)
    signal_seen = 0

  if ($i ~ /^[0-9][0-9][0-9][0-9]$/) {
    channel = i
  }


  else if ($i ~ /signal/ && signal_seen == 0) {
    signal = i+1
    signal_seen = 1
  }




}
printf "%f %d %d\n", $1, sub_channel($channel), $signal 

}

