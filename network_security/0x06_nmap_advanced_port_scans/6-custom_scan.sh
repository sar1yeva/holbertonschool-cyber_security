\#!/bin/bash

# Check arguments
if [ $# -ne 2 ]; then
    exit 1
fi

HOST="$1"
PORTS="$2"

# Run scan
sudo nmap --scanflags URGACKPSHRSTSYNFIN -p "$PORTS" -oN custom_scan.txt "$HOST" > /dev/null 2>&1
