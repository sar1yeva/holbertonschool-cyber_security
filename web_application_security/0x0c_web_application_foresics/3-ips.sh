#!/bin/bash
grep -E 'sshd.*Accepted password for root' auth.log | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u | wc -l
