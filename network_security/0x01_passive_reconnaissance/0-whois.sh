#!/bin/bash
whois "$1" | awk -F: '/^Registrant|^Admin|^Tech/ {if ($1 ~ /Ext/) $1=$1":"; if ($2=="") $2=" "; print $1 "," $2}' > "${1}.csv"
