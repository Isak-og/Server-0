#!/bin/bash

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_DIR="../logs"
LOG_FILE="$LOG_DIR/sysinfo_$TIMESTAMP.log"

mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

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
echo
echo "=========Resource================"
echo
echo "CPU Cores : $(nproc)"
echo "Memory	: $(free -h | awk '/Mem:/ {print $3 " / " $2}')"
echo "Disk (/)	: $(df -h / | awk 'NR==2 {print $5}')"
echo
echo "========= Network ==============="
echo
echo "IP Address : $(hostname -I | awk '{print $1}')"
echo "Gateway	 : $(ip route | awk '/default/ {print $3}')"
echo
echo "========= Health Check =========="
echo
disk_usage=$(df / | awk 'NR==2 {gsub("%","",$5); print $5}')
if [ "$disk_usage" -ge 80 ]; then
	echo "Disk usage : ${disk_usage}% -> [WARNING]"
elif [ "$disk_usage" -ge 60 ] && [ "$disk_usage" -le 79 ]; then
	echo "Disk usage : ${disk_usage}% -> [CAUTION]"
else
	echo "Disk usage : ${disk_usage}% -> [OK]"
fi
memory_usage=$(free | awk '/Mem:/ {printf "%.0f", $3/$2 *100}')
if [ "$memory_usage" -ge 80 ]; then
	echo "Memory usage : ${memory_usage}% -> [WARNING]"	
elif [ "$memory_usage" -ge 60 ] && [ "$memory_usage" -le 79 ]; then
	echo "Memory usage : ${memory_usage}% -> [CAUTION]"
else
	echo "Memory usage : ${memory_usage}% -> [OK]"
fi
echo
echo "======== Top Processes =========="
echo 
ps -eo pid,%cpu,%mem,comm --sort=-%cpu | head -n 6
echo
echo "========= $(date) =============" >> "$LOG_FILE"
echo
echo "========== Docker Status =========="
echo
if ! command -v docker >/dev/null 2>&1; then

    echo "Docker is not installed."

else

    if docker ps --format '{{.Names}}' | grep -q "^portfolio-container$"; then

        echo "Website Status : ONLINE"

    else

        echo "Website Status : OFFLINE"

    fi

fi
echo
if docker info >/dev/null 2>&1; then
    echo "Docker Service : Running"

    echo "Total Containers : $(docker ps -aq | wc -l)"
    echo "Running          : $(docker ps -q | wc -l)"
    echo "Stopped          : $(docker ps -aq -f status=exited | wc -l)"
    echo "Restarting       : $(docker ps -aq -f status=restarting | wc -l)"
    echo "Paused           : $(docker ps -aq -f status=paused | wc -l)"
    echo "Dead             : $(docker ps -aq -f status=dead | wc -l)"

    echo
    echo "Running Containers"
    docker ps --format "  {{.Names}} - {{.Status}}"

    echo
    echo "Stopped Containers"
    docker ps -a --filter status=exited --format "  {{.Names}} - {{.Status}}"

else
    echo "Docker Service : Not Running"
fi
