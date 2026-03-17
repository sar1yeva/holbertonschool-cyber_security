#!/bin/bash
sudo nmap --scanflags URGACKPSHRSTSYNFIN -p $2 -oN custom_scan.txt $1 > /dev/null 2>&1
