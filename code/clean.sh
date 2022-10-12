#!/bin/bash

# extract only our probe requests with proper time
tcpdump -r $1 ether host e8:50:8b:43:b1:20 -tt --time-stamp-precision=nano |

# extract only the time and the channel it was sent on
awk '{if ($4 ~ /bad-fcs/) {print $1" "$7" " $12} else if ($4 ~ /short/) {print $1" "$9" "$14} else {print $1" "$6" "$11}}' |

awk ' {gsub(2412,1); gsub(2437,6); gsub(2462,11); print $0 }' |

tail -n+2 > $2


