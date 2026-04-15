#!/bin/bash
grep "Accepted password" auth.log* | awk '{for(i=1;i<=NF;i++){if($i=="from"){print $(i+1)}}}' | sort -u | wc -l
