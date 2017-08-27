#!/bin/bash

GUITARIX_BAK=guitarix.bak.tgz
GUITARIX=guitarix
JACK=jackd

JACK_PID=$(ps -A | grep $JACK | awk -F' ' '{ print $1 }')

rm -f ./nohup.out
rm -Rf $HOME/.config/guitarix
tar xzf $GUITARIX_BAK --directory=$HOME/.config/

handle_signal() {
	JACK_PID=$(ps -A | grep $JACK | awk -F' ' '{ print $1 }')
	if [ -n "$JACK_PID" ]; then
		kill -2 $JACK_PID
		sleep 1
	fi
	GUITARIX_PID=$(ps -A | grep $GUITARIX | awk -F' ' '{ print $1 }')
	if [ -n "$GUITARIX_PID" ]; then
		kill -2 $GUITARIX_PID
		sleep 1
	fi
	exit 1
}

trap handle_signal SIGINT 

if [ -z "$JACK_PID" ]; then
	nohup $JACK -r -dalsa -r48000 -p1024 -n2 -m -Xseq -D -Chw:U0xd8c0x0c,0 -Phw:U0xd8c0x0c,0 &
	sleep 1
fi
JACK_PID=$(ps -A | grep $JACK | awk -F' ' '{ print $1 }')

if [ -n "$JACK_PID" ]; then
	GUITARIX_PID=$(ps -A | grep $GUITARIX | awk -F' ' '{ print $1 }')
	if [ -z "$GUITARIX_PID" ]; then
		nohup $GUITARIX -K --nogui &
		sleep 1
	fi
fi

while true; do
	sleep 30
done
