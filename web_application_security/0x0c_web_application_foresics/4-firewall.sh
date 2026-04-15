#!/bin/bash
grep -i "iptables" auth.log* | grep -i "add" | wc -l
