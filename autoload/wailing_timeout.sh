#!/bin/bash

if [ $# -lt 2 ]; then
	>&2 echo "Usage: `basename $0` {seconds to sleep} {mpv socket} [reward] [start] [length]"
	exit 1
fi

if [ -e "$2" -a ! -S "$2" ]; then
	>&2 echo "Cannot use existing file as socket!"
	exit 1
fi

echo $$
sleep "$1"


echo "stop"|socat - "$2"

if [ $#  -eq 3 ]; then
	mpv --input-unix-socket="$2" "$3"
elif [ $#  -eq 4 ]; then
	mpv --input-unix-socket="$2" "$3" --start="$4"
elif [ $#  -eq 5 ]; then
	mpv --input-unix-socket="$2" "$3" --start="$4" --length="$5"
fi
