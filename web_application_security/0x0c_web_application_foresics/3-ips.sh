#!/bin/bash
grep "Accepted password for" auth.log* | awk '{print $11}' | sort -u | wc -l
