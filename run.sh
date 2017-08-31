#!/bin/bash

BASEPATH=/opt/guitarix-box
GUITARIX_BAK=guitarix.bak.tgz
GUITARIX=guitarix
JACK=jackd

JACK_PID=$(ps -A | grep $JACK | awk -F' ' '{ print $1 }')

cd $BASEPATH
rm -Rf $HOME/.config/guitarix
tar xzf $GUITARIX_BAK --directory=$HOME/.config/

kill_process_by_name(){
	PNAME=$1
	echo "GB> killing $PNAME"
	for SIG in 2 2 2 3 3 15 9; do
		PID=$(ps -A | grep $PNAME | awk -F' ' '{ print $1 }')
		if [ -n "$PID" ]; then
			echo "GB> kill $PID $SIG"
			kill -n $SIG $PID
			sleep 2
		fi
	done
}

handle_signal() {
	echo ""
	echo "GB> manejando SIGINT"
	kill_process_by_name $GUITARIX
	kill_process_by_name $JACK
	exit 0
}

trap handle_signal SIGINT 
echo "GB> TRAP SIGINT"

if [ -z "$JACK_PID" ]; then
	echo "GB> JACKD START"
	export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/dbus/system_bus_socket
	nohup $JACK -dalsa -r48000 -p1024 -n2 -m -Xseq -D -Chw:U0xd8c0x0c,0 -Phw:U0xd8c0x0c,0 &
	sleep 1
fi
JACK_PID=$(ps -A | grep $JACK | awk -F' ' '{ print $1 }')
echo "GB> JACKD PID: $JACK_PID"

if [ -n "$JACK_PID" ]; then
	echo "GB> GUITAR START"
	GUITARIX_PID=$(ps -A | grep $GUITARIX | awk -F' ' '{ print $1 }')
	echo "GB> GUITAR PID: $GUITARIX_PID"
	if [ -z "$GUITARIX_PID" ]; then
		nohup $GUITARIX -K --nogui &
		GUITARIX_PID=$!
		sleep 1
	fi
	echo "GB> NEW GUITAR PID: $GUITARIX_PID"
fi

while true; do
	sleep 2
done
