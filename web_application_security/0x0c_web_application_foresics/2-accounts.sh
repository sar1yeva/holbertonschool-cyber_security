#!/bin/bash
tail -n 1000 auth.log* | grep "Failed password for" | awk '{for(i=1;i<=NF;i++){if($i=="for"){print $(i+1)}}}' | sort | uniq -c | sort -nr | head -1 | awk '{print $2}'
