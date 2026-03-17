#!/bin/bash
sudo nmap -sF -f -T2 -p 80-85 $1
