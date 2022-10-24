'''
The question we are answering is the following:
    1. Are interarrival times within and between scans consistent for a device
       across multiple runs?

To answer (1), we'll use a bar plot for each bin in it's own respectful
category (same channel and close, same channel and far, etc) across 5 runs. 
We'll also be doing pairwise comparisons between each pair of elements within
a group to determine if 











'''

import sys

# driver function


def main():
    if len(sys.argv) != 2:
        print("usage: python3 analyze.py filename")
        sys.exit(-1)

    data = read_data()
    bins = bin_data(data)
    print(bins)
    # generate_hist(bins)


# read in data into
def read_data():
    odata = []
    with open(sys.argv[1]) as file:
        data = file.read().strip().split('\n')
        for i in range(len(data)):
            odata.append(data[i].split(' '))

    return odata


def bin_data(data):
    same_bins_close = {}
    same_bins_far = {}
    dif_bins_close = {}
    dif_bins_far = {}
    for start in ["1", "6", "11"]:
        for end in ["1", "6", "11"]:
            if start == end:
                same_bins_close[start + end] = []
                same_bins_far[start + end] = []

            else:
                dif_bins_close[start + end] = []
                dif_bins_far[start + end] = []

    for i in range(len(data)):
        if i == 0 or i == len(data) - 1:
            continue

        try:
            start = data[i][1]
            end = data[i][2]

            # short time between same
            if start == end and float(data[i][0]) < 2:
                same_bins_close[start + end].append(float(data[i][0]))

            # long time between same
            if start == end and float(data[i][0]) >= 2:
                same_bins_far[start + end].append(float(data[i][0]))

            # long time between dif
            if start != end and float(data[i][0]) >= 2:
                dif_bins_far[start + end].append(float(data[i][0]))

            # short time between dif
            if start != end and float(data[i][0]) < 2:
                dif_bins_far[start + end].append(float(data[i][0]))

            else:
                print("Issue line:")
                print(data[i])

        except:
            pass


main()



















