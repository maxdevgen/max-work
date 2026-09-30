#!/usr/bin/env bash
# Lehký test a měření teplot — orchestrace kroků 0–5 z docs/26-09-28.1109_SAPPHIRE_lehky-test-a-teploty/
# Výstup: docs/YY-MM-DD.HHMM_SAPPHIRE_lehky-test/ (každý běh vlastní adresář)
# Watchdog: SSD Composite >= 60 °C nebo CPU Tctl >= 90 °C → zátěž se ukončí, další zátěžové fáze se přeskočí
set -uo pipefail

here=$(cd "$(dirname "$0")" && pwd)
TS=${TS:-$(TZ=Europe/Prague date '+%y-%m-%d.%H%M')}
OUT="$(cd "$here/../docs" && pwd)/${TS}_SAPPHIRE_lehky-test"
mkdir -p "$OUT"
P="$OUT/${TS}_SAPPHIRE_test"
SSD_MAX=60; CPU_MAX=90
BASE=${BASE:-300}; CPU_T=${CPU_T:-300}; COOL1=${COOL1:-180}; COOL2=${COOL2:-300}
FIO_FILE="$HOME/fio-test.bin"

hw() { for h in /sys/class/hwmon/hwmon*; do [[ $(cat "$h/name") == "$1" ]] && echo "$h" && return; done; }
NVME=$(hw nvme); CPU=$(hw k10temp)
temp() { echo $(( $(cat "$1") / 1000 )); }

aborted=0
phase() { echo "$(date '+%H:%M:%S'),$1,$2" >> "$P-30-phases.csv"; echo "[$(date '+%H:%M:%S')] $1 $2"; }

# Spustí příkaz na pozadí a hlídá teploty; při překročení limitu ho ukončí
guarded() {
  local name=$1; shift
  if (( aborted )); then phase "$name" skipped; return; fi
  phase "$name" start
  "$@" > "$P-$name.log" 2>&1 &
  local pid=$!
  while kill -0 "$pid" 2>/dev/null; do
    local s c; s=$(temp "$NVME/temp1_input"); c=$(temp "$CPU/temp1_input")
    if (( s >= SSD_MAX || c >= CPU_MAX )); then
      pkill -P "$pid" 2>/dev/null; kill "$pid" 2>/dev/null
      aborted=1; phase "$name" "ABORT ssd=$s cpu=$c"
      wait "$pid" 2>/dev/null; return
    fi
    sleep 2
  done
  wait "$pid"; phase "$name" "end rc=$?"
}

idle() { phase "$1" start; sleep "$2"; phase "$1" end; }

cleanup() {
  [[ -n ${LOGPID:-} ]] && kill "$LOGPID" 2>/dev/null
  pkill -x stress-ng 2>/dev/null; pkill -x fio 2>/dev/null
  rm -f "$FIO_FILE"
}
trap cleanup EXIT

echo "time,phase,event" > "$P-30-phases.csv"

# Krok 0 + 1 — root část (jeden pkexec dialog)
phase root start
pkexec "$here/light-test-root.sh" "$P" "$(id -un)"; phase root "end rc=$?"
{ free -h; cat /sys/class/drm/card*/device/mem_info_vram_total; } > "$P-15-memory.txt"
sensors > "$P-16-sensors.txt" 2>&1
for c in stress-ng fio; do command -v "$c" >/dev/null || { echo "Chybí $c — konec."; exit 1; }; done

# Krok 2 — záznam teplot
"$here/temp-log.sh" "$P-20-teploty.csv" 5 > /dev/null &
LOGPID=$!

# Krok 3–5
idle    baseline "$BASE"
guarded 41-cpu25 stress-ng --cpu 6  --timeout "$CPU_T" --metrics-brief
guarded 42-cpu50 stress-ng --cpu 12 --timeout "$CPU_T" --metrics-brief
idle    cool1 "$COOL1"
guarded 51-ssd-write   fio --name=seqwrite --filename="$FIO_FILE" --size=1G --rw=write --bs=1M --direct=1 --ioengine=libaio --iodepth=8
guarded 52-ssd-read    fio --name=seqread  --filename="$FIO_FILE" --size=1G --rw=read  --bs=1M --direct=1 --ioengine=libaio --iodepth=8 --time_based --runtime=20
guarded 53-ssd-randread fio --name=randread --filename="$FIO_FILE" --size=1G --rw=randread --bs=4k --direct=1 --ioengine=libaio --iodepth=1 --time_based --runtime=30
rm -f "$FIO_FILE"
idle    cool2 "$COOL2"

phase done "aborted=$aborted"
