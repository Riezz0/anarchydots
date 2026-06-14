#!/bin/bash
# Read CPU stats from /proc/stat
read -r cpu user nice system idle iowait irq softirq steal <<< $(head -1 /proc/stat)
total=$((user + nice + system + idle + iowait + irq + softirq + steal))
idle_total=$((idle + iowait))

# Read previous values from temp file
PREV_FILE="/tmp/cpu_usage_prev"
if [ -f "$PREV_FILE" ]; then
    read -r prev_total prev_idle < "$PREV_FILE"
    diff_total=$((total - prev_total))
    diff_idle=$((idle_total - prev_idle))
    if [ "$diff_total" -gt 0 ]; then
        usage=$(( (diff_total - diff_idle) * 100 / diff_total ))
    else
        usage=0
    fi
else
    usage=0
fi

# Save current values
echo "$total $idle_total" > "$PREV_FILE"
echo "$usage"