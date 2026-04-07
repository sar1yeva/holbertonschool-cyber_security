#!/bin/bash

log_file=${1:-logs.txt}

# Find attacker IP
attacker_ip=$(awk '{print $1}' "$log_file" | sort | uniq -c | sort -nr | head -n 1 | awk '{print $2}')

# Count total requests by attacker
awk -v ip="$attacker_ip" '$1==ip {count++} END {print count}' "$log_file"
