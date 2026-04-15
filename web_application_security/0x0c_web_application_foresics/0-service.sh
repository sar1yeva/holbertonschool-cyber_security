#!/bin/bash
grep -hoP 'pam_unix\(\K[^:]+' /var/log/auth.log* | sort | uniq -c | sort -nr
