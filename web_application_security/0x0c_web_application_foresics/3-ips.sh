#!/bin/bash
grep "Accepted password" auth.log* | awk '{print $(NF-3)}' | sort -u | wc -l
