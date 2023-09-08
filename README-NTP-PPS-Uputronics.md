# PPS and NTP and Uputronics R.Pi Hat

# The basics that you will need as you proceed
Starting off, I assume a clean new empty system. I also assume you have setup a username/password (vs using `pi` or `root`) to connect to your R.Pi.

First and formost, because everyone says do this; I will also say do this.
```
sudo apt update && sudo apt upgrade -y
```

Then install all the needed s/w. Note that I do load up a few extra things ('cause Python); however, this is all a quick process.
```
# The absolute basics.
sudo apt-get install -y git vim

# The Python install (to get everything correct).
sudo apt install --upgrade python3 pip
sudo python -m pip install --upgrade pip
sudo pip install pyboard pyserial rshell

# The galmon compile requires these.
sudo apt-get install -y protobuf-compiler libh2o-dev libcurl4-openssl-dev libssl-dev libprotobuf-dev libh2o-evloop-dev libwslay-dev libncurses5-dev libeigen3-dev libzstd-dev g++

# Grab galmon and compile.
mkdir -p ~/src/github/berthubert
cd ~/src/github/berthubert
git clone https://github.com/berthubert/galmon.git --recursive
cd galmon
make clean
# this could take a while - go get a coffee.
make ubxtool

# This is taken from the galmon README; it's the quick verion.
sudo mkdir -p /usr/local/ubxtool
sudo cp ubxtool /usr/local/ubxtool/ubxtool
sudo cp ubxtool.service /etc/systemd/system/
```

## Customize for your station.
There's five files - each with values unique to your station.

### constellations
For Series9 chips: constellations should be ...
```
--galileo --gps --glonass --beidou
```
For Series8 chips: constellations could be one of these lines ...
```
--galileo --gps --glonass
--galileo --gps --beidou
```
Other values could be there - but you should only have three constellations listed.

### station & destination
These are the values you get from Bert

### owner
This would be a short string to explain who you are ... **John Doe** for example

### remark
This would be a short string to explain about the station ... **Uputronics ZED-F9P RPi4B on roof** for example

```
# These files should be edited for your own setup.
( cd /usr/local/ubxtool ; sudo vi constellations station destination owner remark )
```
## raspi-config
You need to add the serial ports etc under **Interface Options** section:

Enable serial (with no login).
Enable i2c and spi just for grins.
```
sudo raspi-config 
# Assues you did that correctly ...
sudo reboot now
```
## Starting galmon
After the reboot, it's time to start up galmon!
```
sudo systemctl enable ubxtool
sudo systemctl start ubxtool
sudo systemctl status ubxtool

tail -f /run/ubxtool/stderr.log 
^C
```

If you have galmon-channels.sh wait a few mins and run it ...
```
./galmon-channels.sh 
```
BTW: galmon-channels.sh is from [https://github.com/mahtin/galmon-channels](galmon-channels).

## NTP setup
Install NTP and confirm it works in it's basic setup (i.e. before PPS support).
```
	sudo apt install -y ntp pps-tools libcap-dev 

	# prove it's up and working ...
	systemctl status ntp
	ntpq -c peers
```

## PPS support.
These are the new PPS support lines for /etc/ntp.conf -- add anywhere - these are found all over the Interwebs; they are correct.
```
#
# Address: 127.127.22.u
# Reference ID: PPS
# Driver ID: PPS
# Serial or Parallel Port: /dev/ppsu
# Requires: PPSAPI interface
#
# http://doc.ntp.org/4.2.0/drivers/driver22.html
# Fudge Factors
#
#   time1 time		; Specifies the time offset calibration factor, in seconds and fraction, with default 0.0.
#   time2 time		; Not used by this driver.
#   stratum number	; Specifies the driver stratum, in decimal from 0 to 15, with default 0.
#   refid string	; Specifies the driver reference identifier, an ASCII string from one to four characters, with default PPS.
#   flag1 0 | 1		; Not used by this driver.
#   flag2 0 | 1		; Specifies the PPS signal on-time edge: 0 for assert (default), 1 for clear.
#   flag3 0 | 1		; Controls the kernel PPS discipline: 0 for disable (default), 1 for enable.
#   flag4 0 | 1		; Not used by this driver.

server 127.127.22.0 minpoll 4 maxpoll 4
fudge 127.127.22.0 time1 +0.000000 flag2 0 flag3 0 refid PPS
```

Hence do these commands:
```
sudo vi /etc/ntp.conf

sudo systemctl stop ntp
sudo systemctl start ntp
sudo systemctl status ntp
```

PPS won't be running yet because you need some module support. Two files still to edit.

In `/etc/modules` this is needed:
```
i2c-dev
pps-gpio
```

In `/boot/config.txt` this is needed.  Add the following to `/boot/config.txt` near the other `dtoverlay` lines:
```
# PPS (for Uputronics and NTP)
dtoverlay=pps-gpio,gpiopin=18
```

Now do those edits:
```
sudo vi /etc/modules
sudo vi /boot/config.txt 

# and then reboot to kick all that into gear
sudo reboot now
```

## Checking it all over
Finally you should have a system that performs fully.
```
lsmod | grep pps
dmesg | grep pps
ls -l /dev/pps*

ntpq -c peers
```

You are looking for this in your configuration:
```
$ ntpq -c peers
     remote           refid      st t when poll reach   delay   offset  jitter
==============================================================================
oPPS(0)          .PPS.            0 l    9   16  377    0.000   +0.002   0.002
...
$
```
That `o` in the first column just before `PPS` means: the host is selected for synchronisation and the PPS signal is in use.
This is a good thing.

## Success!
You have successfully and cleanly installed galmon, NTP, PPS, and a Uputronic Hat on a R.Pi.
