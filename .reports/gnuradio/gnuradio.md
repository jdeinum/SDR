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
pybombs prefix init ~/prefix3.7
pyombs config default_prefix ~/prefix3.7
pybombs recipes add-defaults
```

Now we need to make sure that the modules we plan on using are built for
gnuradio 3.7. Edit:

```
~/prefix3.7/.pybombs/recipes/gr-recipes/gnuradio.lwr
~/prefix3.7/.pybombs/recipes/gr-recipes/gr-ieee-80211.lwr
~/prefix3.7/.pybombs/recipes/gr-recipes/gr-foo.lwr
```

and change the default branch to maint3.7.



1. install pip2.7
2. install mako and six using pip 2.7
3. install cheetah, lxml, pygtk, numpy using pip2.7
3. Install pygtk using https://askubuntu.com/questions/1235271/pygtk-not-available-on-focal-fossa-20-04
https://askubuntu.com/questions/1265294/pyqt4-on-ubuntu-20-04-install
 libqt4-dev



## Building
Now we are ready to build. Run:

```
pybombs install gr-ieee-80211
```


