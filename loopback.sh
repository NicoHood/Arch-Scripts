#!/bin/bash

echo "First plug in and select the correct line input. USB cards give better quality than internal soundcards."
pacmd load-module module-loopback
read -p "Press enter to stop loopback"
pacmd unload-module module-loopback
