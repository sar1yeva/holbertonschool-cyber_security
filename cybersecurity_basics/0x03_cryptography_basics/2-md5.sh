#!/bin/bash
echo -n "$1" | md5sum | cut -d' ' -f1 > 2_hash.txt
