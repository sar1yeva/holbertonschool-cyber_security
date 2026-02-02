#!/bin/bash
hashcat --force --stdout -a 1 "$1" "$2"
