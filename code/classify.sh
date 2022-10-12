#!/bin/bash

tcpdump -r $1 2>/dev/null | 
awk '{if ($4 ~ /bad-fcs/) {print $12} else {print $11}}' | 
rg -o '[0-9]+' |
python3 -c ' 
import numpy as np
import sys
from pandas import Series
import pandas as pd

x = []

for line in sys.stdin:
  x.append(int(line.strip()))

x = Series(data=x)
print(x.describe())
'

    




