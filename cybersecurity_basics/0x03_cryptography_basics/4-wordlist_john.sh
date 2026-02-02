#!/bin/bash
john --format=Raw-SHA256 --wordlist=/usr/share/wordlists/rockyou.txt "$1" > /dev/null 2>&1
john --format=Raw-SHA256 --show "$1" | head -n -1 | cut -d: -f2 > 4-password.txt
