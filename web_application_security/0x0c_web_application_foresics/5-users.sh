#!/bin/bash
grep -E "useradd|adduser" auth.log* | awk '{for(i=1;i<=NF;i++){if($i=="useradd" || $i=="adduser"){print $(i+1)}}}' | sort -u | paste -sd,
