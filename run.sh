#!/bin/bash

BASEPATH=/opt/guitarix-box
GUITARIX_BAK=guitarix.bak.tgz
GUITARIX=guitarix
JACK=jackd

PPID=$(ps -Af | grep $$ | awk -F ' ' '{ print $3 }')
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
	kill -s SIGUSR2 $PPID
	echo ""
	echo "GB> manejando SIGINT"
	kill_process_by_name $GUITARIX
	kill_process_by_name $JACK
	kill -s SIGUSR1 $PPID
	exit 0
}

kill -s SIGUSR2 $PPID
echo "GB> TRAP SIGINT"
trap handle_signal SIGINT

if [ -z "$JACK_PID" ]; then
	echo "GB> JACKD START"
	export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/dbus/system_bus_socket
	nohup $JACK -dalsa -r48000 -p1024 -n2 -m -Xseq -D -Chw:Device,0 -Phw:Device,0 &
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

kill -s SIGUSR1 $PPID
while true; do
	sleep 2
done
