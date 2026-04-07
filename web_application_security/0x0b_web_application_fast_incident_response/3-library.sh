#!/bin/bash

log_file=${1:-logs.txt}

# Find attacker IP
attacker_ip=$(awk '{print $1}' "$log_file" | sort | uniq -c | sort -nr | head -n 1 | awk '{print $2}')

# Extract User-Agent used by attacker and find the most common
awk -v ip="$attacker_ip" '$1==ip {match($0, /"[^"]*"$/, a); print a[0]}' "$log_file" | tr -d '"' | sort | uniq -c | sort -nr | head -n 1 | awk '{print $2}'
