#!/bin/bash

log_file=${1:-logs.txt}

# Find attacker IP
attacker_ip=$(awk '{print $1}' "$log_file" | sort | uniq -c | sort -nr | head -n 1 | awk '{print $2}')

# Extract User-Agent used by attacker and find the most common
awk -v ip="$attacker_ip" '$1==ip {print substr($0, index($0,$12))}' "$log_file" | sort | uniq -c | sort -nr | head -n 1 | awk '{print $2}'
