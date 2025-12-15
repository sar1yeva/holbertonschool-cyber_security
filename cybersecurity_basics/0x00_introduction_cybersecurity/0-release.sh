#!/bin/bash
lsb_release -i | cut -f2 | tr -d '[:space:]'

