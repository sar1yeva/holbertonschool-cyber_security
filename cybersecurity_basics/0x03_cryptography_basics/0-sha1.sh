#!/bin/bash
echo -n "$1" | sha1sum | cut -d' ' -f1 > 0_hash.txt
