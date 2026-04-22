#!/bin/bash
nmap --script=vulners -p 80,443 $1
