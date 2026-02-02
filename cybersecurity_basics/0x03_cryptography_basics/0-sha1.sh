#!/bin/bash
printf "%s" "$1" | sha1sum | cut -d' ' -f1 > 0_hash.txt
