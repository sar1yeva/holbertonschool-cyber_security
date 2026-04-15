#!/bin/bash
grep "Accepted" auth.log 2>/dev/null | grep -oE "from ([0-9]+\.){3}[0-9]+" | awk '{print $2}' | sort -u | wc -l
