#!/bin/bash
used=$(cat /sys/class/drm/card1/device/mem_info_vram_used)
total=$(cat /sys/class/drm/card1/device/mem_info_vram_total)
echo "$used $total"