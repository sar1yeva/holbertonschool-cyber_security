#!/bin/bash
grep -Ev '^\s*#|^\s*$' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null
