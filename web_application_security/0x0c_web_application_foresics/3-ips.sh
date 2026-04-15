#!/bin/bash
awk '$9 == 200 {print $1}' access.log | sort -u | wc -l
