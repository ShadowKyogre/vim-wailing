#!/bin/bash

if [ $# -ne 2 ]; then
	>&2 echo "Usage: `basename $0` {seconds to sleep} {mpv socket}"
	exit 1
fi

echo $$
sleep $1
echo "stop"|socat - $2
