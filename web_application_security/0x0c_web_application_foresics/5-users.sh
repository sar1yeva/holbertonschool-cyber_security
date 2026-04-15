#!/bin/bash
grep -E "useradd|adduser" auth.log* | awk '{print $NF}' | sort -u | paste -sd,
