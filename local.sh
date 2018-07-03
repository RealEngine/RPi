#!/bin/bash -ex

CONFIGFILE="$(pwd)/config.yml"
DATE=$(date +%Y-%m-%d-%H.%M)

# do we have a cfg sdcard?
if sudo fdisk -l | grep sda1 | grep FAT32; then
	if ! mount | grep mnt | cut -d ' ' -f 1 | grep /dev/sda1; then
		sudo mount /dev/sda1 /mnt
	fi
	FILE="/mnt/config.yml"
	if [[ -f "$FILE" ]]; then
		CONFIGFILE="$FILE"
	fi
fi

MQTTHOST=$(grep mqtthostname: $CONFIGFILE | sed 's/mqtthostname: //')
HOSTNAME=$(grep hostname: $CONFIGFILE | sed 's/mqtthostname: //')

echo "using cfg from $CONFIGFILE"
echo "MQTT at $MQTTHOST"
echo "this host called $HOSTNAME"

# 
if [[ ¨$1¨ != ¨--setup¨ ]]; then
	sleep 10
	ping -c 1 $MQTTHOST

	python rfid/main.py $CONFIGFILE > rfid-${DATE}.log 2>&1 &
	python audio/main.py $CONFIGFILE > audio-${DATE}.log 2>&1 &
	python controller/main.py $CONFIGFILE > controller-${DATE}.log 2>&1 &
	#/usr/bin/nohup sudo python neopixels/main.py $CONFIGFILE > neopixel-${DATE}.log 2>&1 &

	echo "DONE"
	exit
fi

# otherwise, setup..

# get pyscard
sudo apt-get update
sudo apt-get upgrade -yq
sudo apt-get install -yq python-pyscard python-pip pcscd git python-setuptools libpcsclite-dev python-dev mosquitto-clients mosquitto scratch python-pygame

git pull

cd rfid
sudo pip install --no-cache-dir -r requirements.txt
cd ../audio
sudo pip install --no-cache-dir -r requirements.txt
cd ../controller
sudo pip install --no-cache-dir -r requirements.txt
cd ..

cat /proc/device-tree/model
if grep "Raspberry Pi" /proc/device-tree/model; then
	if ! lsmod | grep hifiberry; then
		echo "installing drivers for pHAT"
		curl https://get.pimoroni.com/phatdac | bash
	fi
fi
