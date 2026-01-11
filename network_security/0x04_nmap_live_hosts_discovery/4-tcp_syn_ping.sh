#!/bin/bash
sudo nmap $1 -sn -PS22,80,443
