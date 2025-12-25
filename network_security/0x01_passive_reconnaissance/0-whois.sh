!/bin/bash
whois "$1" | awk -F': ' '/^(Registrant|Admin|Tech)/{v=($2==""?" ":$2); print $1", "v}' > "$1.csv"
