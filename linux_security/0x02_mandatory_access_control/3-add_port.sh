#!/bin/bash
sudo semanage port -a -t http_port_t -p tcp 81 2>/dev/null || sudo semanage port -m -t http_port_t -p tcp 81
