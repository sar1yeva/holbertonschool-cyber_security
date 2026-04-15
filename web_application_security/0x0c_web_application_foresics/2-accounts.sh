#!/bin/bash
tail -n 1000 auth.log* | grep "Failed password for" | awk '{if($(NF-5)=="invalid"){print $(NF-4)} else {print $(NF-5)}}' | sort | uniq -c | sort -nr | head -1 | awk '{print $2}'
