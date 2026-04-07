#!/bin/bash

# Extract all User-Agent strings from logs.txt
# Count them and show the most used one

awk -F\" '{print $6}' logs.txt | sort | uniq -c | sort -nr | head -n1 | awk '{print $2}'
