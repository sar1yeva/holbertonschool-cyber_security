#!/bin/bash
whois "$1" | awk -F': ' '/^(Registrant|Admin|Tech)/{print $1","$2} END{printf "Registrant Phone Ext:,\nRegistrant Fax Ext:,\nAdmin Phone Ext:,\nAdmin Fax Ext:,\nTech Phone Ext:,\nTech Fax Ext:,"}' > "$1.csv"
