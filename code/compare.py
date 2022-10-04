import numpy as np
import matplotlib.pyplot as plt
import sys
import scipy.stats as stat


def main():
    file1 = sys.argv[1]
    file2 = sys.argv[2]

    with open("comparison.txt", "a") as s, open(file1, "r") as f1, open(file2, "r") as f2:

        # times will be a hash map indexed using the previous and current channel
        times1 = {}
        times2 = {}
        number1 = {}
        number2 = {}
        channels = ['1', '6', '11']
        for first in channels:
            for second in channels:
                times1["{}-{}".format(first, second)] = []
                times2["{}-{}".format(first, second)] = []

            number1[first] = 0
            number2[first] = 0

        # fill in the data
        for line in f1:
            time, previous, current = line.strip().split(' ')
            try:
                previous, current = int(float(previous)), int(float(current))
                times1["{}-{}".format(previous, current)].append(float(time))
                number1[int(float(current))] += 1
            except:
                continue

        for line in f2:
            time, previous, current = line.strip().split(' ')
            try:
                previous, current = int(float(previous)), int(float(current))
                times2["{}-{}".format(previous, current)].append(float(time))
                number2[current] += 1
            except:
                continue

        # create all 9 histograms for each
        figure1, axis1 = plt.subplots(3, 2, sharey=True)
        figure2, axis2 = plt.subplots(3, 2, sharey=True)
        figure3, axis3 = plt.subplots(3, 2, sharey=True)
        figure4, axis4 = plt.subplots(3, 2)
        figure5, axis5 = plt.subplots(3, 2)
        figure6, axis6 = plt.subplots(3, 2)

        for index, (desc, times) in enumerate(times1.items()):
            _max = 0
            if len(times) > 0:
                _max = max(times)

            if index < 3:
                axis1[index][0].hist(times, range=(0, _max))
                axis1[index][0].set_title(desc)
                axis4[index][0].hist(times, cumulative=True, density=True)
                axis4[index][0].set_title(desc)
                continue

            elif index < 6:
                index = index % 3
                axis2[index][0].hist(times, range=(0, _max))
                axis2[index][0].set_title(desc)
                axis5[index][0].hist(times, cumulative=True, density=True)
                axis5[index][0].set_title(desc)
                continue

            index = index % 3
            axis3[index][0].hist(times, range=(0, _max))
            axis3[index][0].set_title(desc)
            axis6[index][0].hist(times, cumulative=True, density=True)
            axis6[index][0].set_title(desc)

        for index, (desc, times) in enumerate(times2.items()):
            _max = 0
            if len(times) > 0:
                _max = max(times)

            if index < 3:
                axis1[index][1].hist(times, range=(0, _max))
                axis1[index][1].set_title(desc)
                axis4[index][1].hist(times, cumulative=True, density=True)
                axis4[index][1].set_title(desc)
                continue

            elif index < 6:
                index = index % 3
                axis2[index][1].hist(times, range=(0, _max))
                axis2[index][1].set_title(desc)
                axis5[index][1].hist(times, cumulative=True, density=True)
                axis5[index][1].set_title(desc)
                continue

            index = index % 3
            axis3[index][1].hist(times, range=(0, _max))
            axis3[index][1].set_title(desc)
            axis6[index][1].hist(times, cumulative=True, density=True)
            axis6[index][1].set_title(desc)

        figure1.suptitle("HIST: Phone 1 (left), Phone 2 (right)")
        figure2.suptitle("HIST: Phone 1 (left), Phone 2 (right)")
        figure3.suptitle("HIST: Phone 1 (left), Phone 2 (right)")
        figure4.suptitle("CDF: Phone 1 (left), Phone 2 (right)")
        figure5.suptitle("CDF: Phone 1 (left), Phone 2 (right)")
        figure6.suptitle("CDF: Phone 1 (left), Phone 2 (right)")

        figure1.tight_layout()
        figure2.tight_layout()
        figure3.tight_layout()
        figure4.tight_layout()
        figure5.tight_layout()
        figure6.tight_layout()

        plt.plot()

        figure1.savefig('hist1.png')
        figure2.savefig('hist2.png')
        figure3.savefig('hist3.png')
        figure4.savefig('cdf1.png')
        figure5.savefig('cdf2.png')
        figure6.savefig('cdf3.png')

        # calculate basic stats
        s.write("PHONE 1\n")
        for desc, times in times1.items():
            if (len(times) == 0):
                continue
            s.write("{}: mean: {} , var: {}\n".format(
                desc, np.mean(times), np.var(times)))
        s.write("\n\n\n")

        s.write("PHONE 2\n")
        for desc, times in times2.items():
            if (len(times) == 0):
                continue
            s.write("{}: mean: {} , var: {}\n".format(
                desc, np.mean(times), np.var(times)))
        s.write("\n\n\n")

        # run our KStest
        for first in channels:
            for second in channels:
                key = "{}-{}".format(first, second)
                if (len(times1[key]) == 0 or len(times2[key]) == 0):
                    s.write("{} could not be compared since one of the lists was empty!\n"
                            .format(key))
                    continue
                (stats, p) = stat.kstest(times1[key], times2[key])

                s.write("The p value for the KStest between {} is {}\n"
                        .format(key, p))
        s.write("\n\n\n")

        # compare the count of packets on each channel
        for channel in channels:
            s.write("Channel {} had {} packets transmitted for phone 1\n"
                    .format(channel, number1[channel]))
            s.write("Channel {} had {} packets transmitted for phone 2\n\n"
                    .format(channel, number2[channel]))

        s.write("\n\n\n")
        s.write("Intra Phone Comparisons for Phone 1")


main()




