#!/usr/bin/env bash
# Záznam teplot (SSD, CPU, GPU) a zátěže do CSV — bez sudo, čte /sys/class/hwmon
# Použití: ./temp-log.sh <výstupní.csv> [interval_s=5]
# Ukončení: Ctrl+C
set -euo pipefail

out=${1:?Použití: $0 <výstupní.csv> [interval_s]}
interval=${2:-5}

hw() { for h in /sys/class/hwmon/hwmon*; do [[ $(cat "$h/name") == "$1" ]] && echo "$h" && return; done; }
nvme=$(hw nvme); cpu=$(hw k10temp); gpu=$(hw amdgpu)
t() { [[ -r $1 ]] && echo $(( $(cat "$1") / 1000 )) || echo ""; }

echo "time,ssd_composite_c,ssd_s1_c,ssd_s2_c,cpu_tctl_c,gpu_edge_c,load1,mem_avail_mib" | tee "$out"
while true; do
  load=$(cut -d' ' -f1 /proc/loadavg)
  mem=$(awk '/MemAvailable/ {print int($2/1024)}' /proc/meminfo)
  echo "$(date '+%H:%M:%S'),$(t "$nvme/temp1_input"),$(t "$nvme/temp2_input"),$(t "$nvme/temp3_input"),$(t "$cpu/temp1_input"),$(t "$gpu/temp1_input"),$load,$mem" | tee -a "$out"
  sleep "$interval"
done
