/*
 * Capturing samples using the SDR
 *
 * Although we would like to capture the entire 2.4GHz spectrum (2412 MHz - 2472MHz so 58MHz),
 * the SDR only supports 50MHz, so we have to cut out 8MHz. Since channels
 * 1,6,11 are the only non overlapping intervals, we cut out channels 12 and 13. Therefore 
 * we are left with channels 1-11 (2412MHz - 2462MHz). 
 *
 * So the SDR capturing a 50MHz window at a sample rate of 50MHz, we shouldn't lose any data
 * from the capture and still collect everything that we need.
 *
 * Since the magnitude is captured 50e6 times per second, if we start capturing
 * on our SDR at the same time as our tcpdump / iw , we should in theory be able to see a power
 * increase during the timestamps during the probe requests as well as be able
 * to see if the scans follow the scan plan found (20,40,80,160).
 *
 * In order to confirm whether the timings reported by the kernel are correct,
 * we need to scan for enough seconds to hear a probe response. Since the
 * intervals in between scans (at the Android level) can be up to 160 seconds,
 * in theory we would need to capture for 160 seconds, however this is
 * unfeasible:
 *
 * 160 seconds * 50e6 samples per second * 8 bytes per sample = 20000000000000 bytes = 20000 GB,
 * this isn't too reasonable. 
 *
 * Instead we'll capture a window of about 10 seconds once we determine that a
 * scan is taking place. Using iw, we get 
 *
 */





// this is C99.
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

// set the type of data you want to read here
typedef float sample_type;

int main(int argc, char **argv) {
  if (argc != 2) {
    fputs("Expected one argument!\n", stderr);
    exit(-2);
  }
  FILE *fp = fopen(argv[1], "rb");
  if (!fp) {
    perror("Error opening file");
    exit(-1);
  }

  // allocate a buffer for 1024 samples
  const unsigned int buf_length = 1024;
  sample_type *buffer = malloc(buf_length * sizeof(sample_type));

  // loop until we don't
  while (1) {
    // try to read as many samples as fit the buffer
    size_t read_count = fread(buffer, sizeof(sample_type), buf_length, fp);

    // check for end-of-file / error
    if (!read_count) {
      break;
    }

    for (size_t index = 0; index < read_count - 1; index += 2) {

      double absolute = fabs(buffer[index]) + fabs(buffer[index + 1]);
      printf("%f\n", absolute);
    }
  }
  free(buffer);
  fclose(fp);
}
