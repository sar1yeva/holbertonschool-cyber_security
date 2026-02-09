#!/bin/bash
iptables -P INPUT DROP
iptables -A INPUT -p tcp --dport ssh -j ACCEPT
