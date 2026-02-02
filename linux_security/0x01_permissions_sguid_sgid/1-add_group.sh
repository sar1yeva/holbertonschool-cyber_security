#!/bin/bash
groupadd "$1"
chgrp "$1" "$2"
chmod g+rx "$2"
