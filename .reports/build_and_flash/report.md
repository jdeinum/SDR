# Building and Flashing Stock Android

## Why?
If you take a look at the possible things to capture within the cpu during a
perfetto trace [here](https://ui.perfetto.dev/#!/record/cpu), you can see that
in order to record system calls we need to be in either usr-debug mode or eng
mode. While there are *supposed* ways to change the ROM without building android
from scratch, they explicitly state that the phone will not be stable. Therefore
we'll just stick to building it from scratch.



## Downloading the Source
In order to build a new version of android, we first need the source. One thing
to note is that the source huge (>200GB), so for this experiment we'll use an
external hard drive to store the code on. To download the source, do the
following: 



Create the directory we need for the source code on the external hard drive:
```bash
cd path_to_external_drive
mkdir android_source
cd android_source
```


Setup your git so google can use their advanced tracking algorithm:
```bash
git config --global user.name Your Name
git config --global user.email you@example.com
```

Initialize the repo:
```bash
repo init -u https://android.googlesource.com/platform/manifest
repo init -u https://android.googlesource.com/platform/manifest -b master
```

Sync:
```bash
repo sync -c -j8
```


At this point, you should only have to wait for a really long time and you'll
have the source.


## Building the Source

To build android, do the following:


Setup the environment:
```bash
source build/envsetup.sh
./build/envsetup.sh
```



Now we choose the build we want. We'd like to get an eng build, but currently
there [aren't](https://source.android.com/setup/build/running#selecting-device-build)
any currently available. We'll just stick with the newest user-debug currently
available (might change):

```bash
lunch aosp_raven-userdebug
```

and finally, Build!:
```bash
m
```




## Flashing the Device



