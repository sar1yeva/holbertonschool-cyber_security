#!/bin/bash
ps -u "$1" | grep -v ' 0  *0 '
