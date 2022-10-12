# Setting Up GNUradio


## Installing Prerequisits
I assume here that you are on a fresh Ubuntu 20.04 installation. First, lets
update everything:

```
sudo apt update
sudo apt upgrade
```

Next lets install a few tools we need:

```
sudo apt install python2 python3 python3-pip libcppunit-dev python-dev python3-dev
```

Now we can download pybombs:

```
pip3 install pybombs
```

## Configuring
Now we configure pybombs:

```
pybombs auto-config
pybombs prefix init ~/prefix3.10
pyombs config default_prefix ~/prefix3.10
pybombs recipes add-defaults
```

Now we need to make sure that the modules we plan on using are built for
gnuradio 3.10. Edit:

```
~/prefix3.7/.pybombs/recipes/gr-recipes/gnuradio.lwr
~/prefix3.7/.pybombs/recipes/gr-recipes/gr-ieee-80211.lwr
~/prefix3.7/.pybombs/recipes/gr-recipes/gr-foo.lwr
```

and change the default branch to maint3.10 for each of them.



## Installing
To install all of the needed modules, we run: 

```
cd ~/prefix3.10
pybombs install gr-ieee-80211
```

Once all of the modules are installed and built, we run:

```
source setup_env.sh
./bin/gnuradio-companion &
```

Congrats! We've built gnuradio 3.10 and have all of the modules we need. So what
now? If we open the flow graph located in `~/prefix3.10/src/gr-ieee-80211/examples/wifi_loopback.grc`
we can see that some of the blocks we need are missing. To build these, open
`~/prefix3.10/src/gr-ieee-80211/examples/wifi_phy_hier.grc` and build it. Now
let's move the generated block to the right place:

```
mv ~/.grc_gnuradio/wifi_phy_hier.block.yml ~/prefix3.10/share/gnuradio/grc/blocks/
```

Now if you reopen gnuradio and run `wifi_loopback.grc`, you should see no more
missing blocks and everything works as expected. `wifi_loopback.grc` isn't very
useful for us however. We are more interested in `wifi_rx.grc` since it can
monitor the power of particular channels. This gives us some valuable
information, but nothing that we haven't gotten before. Let's set our eyes on
the prize. RFtap.


## RFtap
[RFtap](https://rftap.github.io/) allows us to see signal properties from inside
tools we are familiar with such as Wireshark, tcpdump, and tshark. 


To install RFtap, we run:

```
cd ~/prefix3.10
pybombs install gr-rftap
```


Once it's installed, lets open up
`~/prefix3.10/src/gr-rftap/examples/wifi_rx_rftap.grc`.

You should a problem immediately. Many of the blocks are missing! Many of them
are related to gnuradio [dropping](https://wiki.gnuradio.org/index.php/GNU_Radio_3.8_OOT_Module_Porting_Guide#WX_is_Gone) 
support for wxgui. They mention that *If you are using WX widgets in your flow
graph, you’d have to replace them with the corresponding QT widgets. For most
flow graphs that should be a straight forward drop in replacement.* 


## Porting RFtap to 3.10
Porting gnuradio to 3.10 will be no easy task. Given that people who have
degrees in electrical engineering still spent a long time making these modules,
I will likely spend much more time and accomplish much less than them due to my
inexperience.


First lets replace the old variable choosers with something new.







