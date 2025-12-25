#!/bin/bash
subfinder -d "$1" -silent | awk '{print $1", "}' > "$1.txt"
