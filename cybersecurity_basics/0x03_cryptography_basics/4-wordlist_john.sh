#!/bin/bash
john --format=Raw-SHA256 --wordlist=/usr/share/wordlists/rockyou.txt "$1"
john --format=Raw-SHA256 --show "$1" | cut -d: -f2 | head -n -3 > 4-password.txt
