#!/bin/bash
grep -hoP 'pam_unix\(\K[^:]+' auth.log* | sort | uniq -c | sort -nr
