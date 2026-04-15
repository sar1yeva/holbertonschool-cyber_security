#!/bin/bash
tail -n 1000 auth.log* | grep "Failed password for" | grep -v "invalid user" | awk '{print $9}' | sort | uniq -c | sort -nr | head -1 | awk '{print $2}'
