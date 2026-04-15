#!/bin/bash
tail -n 1000 auth.log* | grep "Accepted password" | awk '{print $(NF-3)}' | sort -u | wc -l
