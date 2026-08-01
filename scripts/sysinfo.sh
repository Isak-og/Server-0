#!/bin/bash

echo "================================="
echo "Linux Operations Server Dashboard"
echo "================================="

echo

echo "Hostname : $(hostname)"
echo "User     : $(whoami)"
echo "Date     : $(date)"
echo "OS       : $(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')"
echo "Kernel   : $(uname -r)"
echo "Uptime   : $(uptime -p)"

echo "=========Resource================"

echo "CPU Cores : $(nproc)"
echo "Memory	: $(free -h | awk '/Mem:/ {print $3 " / " $2}')"
echo "Disk (/)	: $(df -h / | awk 'NR==2 {print $5}')"
