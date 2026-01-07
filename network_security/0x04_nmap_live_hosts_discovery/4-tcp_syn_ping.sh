#!/bin/bash
sudo nmap $1 -PS -sn -p 22,80,443
