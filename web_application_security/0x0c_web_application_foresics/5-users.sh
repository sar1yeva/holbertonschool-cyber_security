#!/bin/bash
grep 'useradd' auth.log | awk -F 'name=' '{print $2}' | awk '{print $1}' | tr -d ',' | sort -u | paste -sd ',' -
