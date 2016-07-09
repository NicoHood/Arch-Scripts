#!/bin/bash

echo "Please enter the ssh password"
read -s password
port=5902

sshpass -p "$password" ssh samus@taloniv.local -L $port:localhost:$port "x11vnc -display :0 -noxdamage" &
ret=$?
pid=$!
password=""
sleep 3

if [ $ret -ne 0 ]
then
	echo "Error! Wrong password?"
	exit 1
fi

vinagre localhost::5900
kill $pid

if [ $? -ne 0 ]
then
	echo "Error! vinagre exited with error"
	exit 1
fi
