# PPS and NTP and Uputronics R.Pi Hat

# The basics that you will need as you proceed

```
	# Because everyone says do this; I will also say do this.
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

### constellations
For Series9 chips: constellations should be ...
	--galileo --gps --glonass --beidou
For Series8 chips: constellations could be ...
	--galileo --gps --glonass
	--galileo --gps --beidou

### station destination
These are the values you get from Bert

### owner
This would be a short string to explain who you are ... **W6LHI (Martin)** for example

### remark
This would be a short string to explain about the station ... **Uputronics ZED-F9P RPi4B** for example

	# These files should be edited for your own setup.
	( cd /usr/local/ubxtool ; sudo vi constellations station destination owner remark )

	# run raspi-config ...
	# Under Interfaces:
	#	 enable serial (with no login)
	#	 enable i2c and spi just for grins
	sudo raspi-config 

	# Assues you did that correctly ...
	sudo reboot now
```

After the reboot, it's time to start up galmon!
```
	sudo systemctl enable ubxtool
	sudo systemctl start ubxtool
	sudo systemctl status ubxtool

	tail -f /run/ubxtool/stderr.log 
	^C

	# if you have galmon-channels.sh from https://github.com/mahtin/galmon-channels run it ...
	./galmon-channels.sh 
```

## PPS and NTP setup

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

Hence these commands:
```
	sudo vi /etc/ntp.conf

	sudo systemctl stop ntp
	sudo systemctl start ntp
	sudo systemctl status ntp
```

PPS won't be running yet because you need some module support. Two files still to edit.

In /etc/modules this is needed:

```
	i2c-dev
	pps-gpio
```

In /boot/config.txt this is needed.  Add the following to /boot/config.txt near the other dtoverlay lines:
```
	# PPS (for Uputronics and NTP)
	dtoverlay=pps-gpio,gpiopin=18
```

The edits:
	sudo vi /etc/modules
	sudo vi /boot/config.txt 

	# and the reboot to kick all that into gear
	sudo reboot now
```

Finally you should have a system that performs fully. PPS & NTP and Uputronic Hats on a R.Pi cleanly.

```
	lsmod | grep pps
	dmesg | grep pps
	ls -l /dev/pps*

	ntpq -c peers
```
