#!/usr/bin/env bash
# Root část lehkého testu: instalace nástrojů + kontrola zdraví (kroky 0 a 1)
# Spouští se přes pkexec z light-test.sh: pkexec light-test-root.sh <OUT> <TS> <user>
set -uo pipefail

out=${1:?}; ts=${2:?}; owner=${3:?}
p="$out/${ts}_test"

DEBIAN_FRONTEND=noninteractive apt-get install -y -o DPkg::Lock::Timeout=300 \
  smartmontools nvme-cli stress-ng fio > "$p-00-apt.log" 2>&1
echo "apt exit: $?" >> "$p-00-apt.log"

smartctl -a /dev/nvme0 > "$p-11-smartctl.txt" 2>&1
nvme smart-log /dev/nvme0 > "$p-12-nvme-smart-log.txt" 2>&1
lspci -vv -s c3:00.0 2>&1 | grep -E 'LnkCap:|LnkSta:' > "$p-13-pcie-link.txt"
dmesg --level=err,warn > "$p-14-dmesg.txt" 2>&1

chown "$owner:$owner" "$p"-*
