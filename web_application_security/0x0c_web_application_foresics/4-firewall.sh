#!/bin/bash
grep -Ei "iptables|ufw|nft|firewall" auth.log* | grep -Ei "add|append|-A|insert" | wc -l
