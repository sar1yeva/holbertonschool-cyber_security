#!/bin/bash
sudo nmap --scanflags  -p $2 $1 > custom_scan.txt 2>&1
