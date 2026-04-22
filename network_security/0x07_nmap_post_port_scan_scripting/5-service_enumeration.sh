#!/bin/bash
nmap -sS -sV -O -sC --traceroute --script banner,ssl-enum-ciphers,default,smb-enum-domains $1 -oN service_enumeration_results.txt
