#!/bin/bash
hashcat -m 0 -a 0 "$1" /usr/share/wordlists/rockyou.txt --force --quiet --outfile=7-password.txt --outfile-format=2
