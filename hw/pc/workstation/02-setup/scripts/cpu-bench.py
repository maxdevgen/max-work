#!/usr/bin/env python3
"""Společný CPU benchmark pro srovnání strojů (Dell Latitude 5510 vs. SAPPHIRE Edge AI 370).

Stejný kód na Linuxu i Windows. Měří propustnost (jednotky práce za sekundu) po intervalech,
takže je vidět i pokles výkonu v čase (throttling).

Dvě zátěže:
  py   — čistý Python (matematika ve smyčce), podobné skriptování / nástrojům v Pythonu
  zlib — komprese dat (nativní C kód), podobné kompilaci / balení / práci s daty

Použití:
  python cpu-bench.py --out <nadřazená složka> --label <SAPPHIRE|Dell> [--procs 1,8] [--single-sec 30] [--multi-sec 120]
  --procs: čárkami oddělené počty procesů; "all" = všechna logická jádra
  Výstup: <out>/YY-MM-DD.HHMM_<label>_cpu-bench/ se soubory .md (souhrn), .json (průběh), .log (výpis)

Watchdog (jen Linux): CPU >= --cpu-max nebo SSD >= --ssd-max po --over-sec sekund za sebou
→ zátěž se ukončí a další běhy se přeskočí. Na Windows teploty nečte, hlídá uživatel.
"""
import argparse, json, math, multiprocessing as mp, os, platform, sys, time, zlib
from datetime import datetime

INTERVAL = 5
WARMUP = 3
ZDATA = b"".join(b"%08d lorem ipsum dolor sit amet %d\n" % (i, i * 7919 % 10007) for i in range(8000))


def unit_py():
    s = 0.0
    for i in range(1, 40001):
        s += math.sqrt(i) * math.sin(i) / math.log(i + 1)
    return s


def unit_zlib():
    return len(zlib.compress(ZDATA, 6))


UNITS = {"py": unit_py, "zlib": unit_zlib}


def worker(kind, counter, start, stop):
    fn = UNITS[kind]
    start.wait()
    while not stop.is_set():
        fn()
        with counter.get_lock():
            counter.value += 1


def now_prague():
    try:
        from zoneinfo import ZoneInfo
        return datetime.now(ZoneInfo("Europe/Prague"))
    except Exception:  # Windows bez balíčku tzdata — Dell je v Praze, lokální čas stačí
        return datetime.now()


def hwmon_temp(names):
    """Teplota prvního senzoru hwmon s daným jménem (°C) — jen Linux, jinak None."""
    try:
        for h in os.listdir("/sys/class/hwmon"):
            p = f"/sys/class/hwmon/{h}"
            if open(f"{p}/name").read().strip() in names:
                return int(open(f"{p}/temp1_input").read()) // 1000
    except Exception:
        pass
    return None


def linux_sensors():
    """Teplota CPU a nejvyšší takt jádra — jen Linux, jinak None."""
    mhz = None
    try:
        with open("/proc/cpuinfo") as f:
            mhz = max(int(float(l.split(":")[1])) for l in f if l.startswith("cpu MHz"))
    except Exception:
        pass
    return hwmon_temp(("k10temp", "coretemp")), mhz


class Watchdog:
    def __init__(self, cpu_max, ssd_max, over_sec):
        self.cpu_max, self.ssd_max, self.over_sec = cpu_max, ssd_max, over_sec
        self.over, self.tripped = 0, None

    def check(self):
        """Volá se každou sekundu; vrací True, pokud je limit překročen dost dlouho."""
        c, s = hwmon_temp(("k10temp", "coretemp")), hwmon_temp(("nvme",))
        if (c is not None and c >= self.cpu_max) or (s is not None and s >= self.ssd_max):
            self.over += 1
        else:
            self.over = 0
        if self.over >= self.over_sec:
            self.tripped = f"CPU {c} °C, SSD {s} °C"
        return self.tripped is not None


WD = None


class Tee:
    """Výpis na obrazovku i do logu v adresáři měření."""
    def __init__(self, *streams):
        self.streams = streams

    def write(self, text):
        for s in self.streams:
            s.write(text)
            s.flush()

    def flush(self):
        for s in self.streams:
            s.flush()


def run(kind, procs, seconds):
    counters = [mp.Value("q", 0) for _ in range(procs)]
    start, stop = mp.Event(), mp.Event()
    ps = [mp.Process(target=worker, args=(kind, c, start, stop)) for c in counters]
    for p in ps:
        p.start()
    start.set()
    time.sleep(WARMUP)
    aborted = False
    total = lambda: sum(c.value for c in counters)
    last, t_last = total(), time.perf_counter()
    samples = []
    for i in range(seconds // INTERVAL):
        for _ in range(INTERVAL):
            time.sleep(1)
            if WD.check():
                aborted = True
                break
        if aborted:
            print(f"  WATCHDOG: {WD.tripped} — zátěž ukončena", flush=True)
            break
        cur, t_cur = total(), time.perf_counter()
        rate = (cur - last) / (t_cur - t_last)
        temp, mhz = linux_sensors()
        samples.append({"t": (i + 1) * INTERVAL, "units_per_s": round(rate, 2), "cpu_c": temp, "max_mhz": mhz})
        print(f"  {kind:4} procs={procs:2} t={(i + 1) * INTERVAL:4}s  {rate:9.2f} u/s"
              + (f"  cpu {temp} °C  {mhz} MHz" if temp else ""), flush=True)
        last, t_last = cur, t_cur
    stop.set()
    for p in ps:
        p.join()
    rates = [s["units_per_s"] for s in samples] or [0]
    n = max(1, len(rates) // 4)
    first, lastq = sum(rates[:n]) / n, sum(rates[-n:]) / n
    return {
        "kind": kind, "procs": procs, "seconds": seconds,
        "avg_units_per_s": round(sum(rates) / len(rates), 2),
        "first_quarter": round(first, 2), "last_quarter": round(lastq, 2),
        "drop_pct": round((1 - lastq / first) * 100, 1) if first else None,
        "aborted": WD.tripped if aborted else None,
        "samples": samples,
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--procs", default="1,8")
    ap.add_argument("--single-sec", type=int, default=30)
    ap.add_argument("--multi-sec", type=int, default=120)
    ap.add_argument("--kinds", default="py,zlib")
    ap.add_argument("--label", required=True)
    ap.add_argument("--cpu-max", type=int, default=90)
    ap.add_argument("--ssd-max", type=int, default=60)
    ap.add_argument("--over-sec", type=int, default=6)
    a = ap.parse_args()
    global WD
    WD = Watchdog(a.cpu_max, a.ssd_max, a.over_sec)

    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    ncpu = os.cpu_count()
    procs = [ncpu if p == "all" else int(p) for p in a.procs.split(",")]
    ts = now_prague().strftime("%y-%m-%d.%H%M")
    name = f"{ts}_{a.label}_cpu-bench"
    outdir = os.path.join(a.out, name)
    os.makedirs(outdir, exist_ok=True)
    base = os.path.join(outdir, name)
    sys.stdout = Tee(sys.stdout, open(base + ".log", "w", encoding="utf-8"))
    info = {
        "label": a.label, "time": now_prague().isoformat(timespec="seconds"),
        "machine": platform.node(), "os": platform.platform(), "cpu": platform.processor() or platform.machine(),
        "logical_cpus": ncpu, "python": sys.version.split()[0],
    }
    print(json.dumps(info, ensure_ascii=False), flush=True)

    results = []
    for kind in a.kinds.split(","):
        for p in procs:
            secs = a.single_sec if p == 1 else a.multi_sec
            if WD.tripped:
                print(f"  přeskočeno: {kind} procs={p} (watchdog)", flush=True)
                continue
            results.append(run(kind, p, secs))
            time.sleep(10)  # krátká pauza mezi běhy

    lines = [f"# CPU benchmark — {a.label} ({info['time']})", "",
             f"Stroj: {info['machine']}, {info['os']}, {ncpu} logických jader, Python {info['python']}", "",
             "| Zátěž | Procesy | Průměr (jednotek/s) | 1. čtvrtina | Poslední čtvrtina | Pokles |",
             "|---|---:|---:|---:|---:|---:|"]
    for r in results:
        lines.append(f"| {r['kind']} | {r['procs']} | {r['avg_units_per_s']} | {r['first_quarter']} "
                     f"| {r['last_quarter']} | {r['drop_pct']} % |"
                     + (f" ⚠ přerušeno watchdogem: {r['aborted']}" if r["aborted"] else ""))
    summary = "\n".join(lines) + "\n"

    with open(base + ".json", "w", encoding="utf-8") as f:
        json.dump({"info": info, "results": results}, f, ensure_ascii=False, indent=1)
    with open(base + ".md", "w", encoding="utf-8") as f:
        f.write(summary)

    try:
        print("\n" + summary)
    except UnicodeEncodeError:
        print("\n" + summary.encode("ascii", errors="replace").decode("ascii"))
    print(f"Uloženo: {base}.json, {base}.md")


if __name__ == "__main__":
    mp.freeze_support()
    main()
