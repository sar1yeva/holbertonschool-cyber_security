#!/bin/bash
john --wordlist=/usr/share/wordlists/rockyou.txt --format=Raw-SHA256 "$1" && john --show --format=Raw-SHA256 "$1" | awk -F: '{print $2}' | grep -v '^$' > 6-password.txt
