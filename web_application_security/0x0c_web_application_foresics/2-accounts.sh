#!/bin/bash
tail -n 1000 auth.log* | grep "Failed password" | awk '{print $(NF-5)}' | sort | uniq -c | sort -nr | head -1 | awk '{print $2}'
