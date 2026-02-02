#!/bin/bash
john --wordlist=/usr/share/wordlists/rockyou.txt "$1" && john --show "$1" | head -n 1 | cut -d: -f2 > 4-password.txt
