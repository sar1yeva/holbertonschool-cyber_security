#!/bin/bash
whois "$1" | awk -F': ' '
/^(Registrant|Admin|Tech)/{
  if ($1 ~ /Ext/) print $1 ":,"
  else print $1 "," $2
}
END{
  print "Registrant Phone Ext:,"
  print "Registrant Fax Ext:,"
  print "Admin Phone Ext:,"
  print "Admin Fax Ext:,"
  print "Tech Phone Ext:,"
  printf "Tech Fax Ext:,"
}
' > "$1.csv"
