# Problém: Debian instalátor nevidí SSD (jen USB flash disk)

Zjištěno 26-09-27 v 1923, krok partitioning v Debian instalátoru (screenshot uživatele). Založeno 2026-09-27.

## Co ukazuje partition disks obrazovka

Instalátor vidí jen **jeden disk**:

```
SCSI1 (0,0,0) (sda) - 30.9 GB Kingston DataTraveler 3.0
  #1   30.9 GB   fat32   Main Data Pa...
```

To je **USB flash disk s instalátorem** (Kingston DataTraveler, viz [instalační médium](01-instalacni-medium.md)), ne cílový SSD. **Samsung 990 EVO Plus 2 TB (2 TB) v seznamu chybí úplně.**

## Souvislost s dřívější verifikací

V [verifikaci instalace SSD](../../01-before.order/SAPPHIRE/SAPPHIRE_EdgeAI_370/SSD/26-09-26.prevzeti-SSD/26-09-26.1609_Samsung990EVOPlus-2TB_verifikace-instalace.md) bod 3.1 a kontrolní seznam (sekce 13.3.1 hlavního souboru o SSD) byl **plné zasunutí disku v konektoru** označen jako „z fotky nelze stoprocentně potvrdit, ověřit po zapnutí". **Tohle je přesně ten okamžik ověření — a výsledek je negativní** (disk není vidět).

## Diagnostický postup (od nejjednoduššího)

| # | Krok | Co zjistíme |
|---|---|---|
| 1 | Restart, vstup do BIOSu (ne boot z USB), zkontrolovat Storage Information / Boot seznam | jestli SSD vidí **firmware** |
| 2 | Pokud BIOS nevidí: vypnout, sundat víko, zkontrolovat fyzicky zasunutí SSD v konektoru a utažení šroubku (viz [instalace SSD](../../01-before.order/SAPPHIRE/SAPPHIRE_EdgeAI_370/SSD/26-09-26.prevzeti-SSD/26-09-26.1609_Samsung990EVOPlus-2TB_verifikace-instalace.md)) | fyzické/kontaktní připojení |
| 3 | Pokud BIOS vidí, instalátor ne: v instalátoru „Go Back" na hlavní menu, znovu spustit „Detect disks" | dočasná chyba detekce v instalátoru |
| 4 | Terminál v instalátoru (**Alt+F2**), příkazy `lsblk`, `nvme list` | vidí disk jádro Linuxu, i když ho partitioner nenabídl |

## Stav

⏳ **Čeká se na výsledek kroku 1** (kontrola v BIOSu).

## Aktualizace: ověřeno na úrovni jádra (2026-09-27)

V instalátoru, `Execute a shell` (BusyBox):

```
~ # lsblk
/bin/sh: lsblk: not found
~ # ls /sys/block/
sda
~ # cat /proc/partitions
major minor  #blocks  name
   8      0   30218746 sda
   8      1   30217696 sda1
```

**Jádro Linuxu nevidí žádný NVMe disk** (`/sys/block/` obsahuje jen `sda`, žádný `nvme0n1`). Problém tedy není jen v zobrazení partitioneru, ale hlouběji — disk se vůbec neobjevuje jako blokové zařízení.

**Další krok:** `dmesg | grep -i nvme` — pokud nic nenajde, disk se pravděpodobně nezobrazuje ani na PCIe sběrnici, což ukazuje na hardwarový problém (zasunutí/kontakt SSD), ne na chybějící ovladač. Čeká se na výsledek a na kontrolu v BIOSu (krok 1 diagnostiky výše).

## Vyřešeno (2026-09-27, po zásahu uživatele)

**Postup:** vypnutí, odpojení napájení, otevření skříně, **vyjmutí a znovuzasunutí SSD** do slotu 2280, kontrola v BIOSu.

**Výsledek — BIOS (screenshot, System Information):**

| Položka | Hodnota |
|---|---|
| M.2 SSD (NVME 2280) | **Samsung SSD 990 EVO Plus 2TB (2000GB)** ✅ |
| M.2 SSD (NVME 2242) | Not Installed (správně, prázdný slot) |
| Processor | AMD Ryzen AI 9 HX 370 w/ Radeon 890M |
| Total Memory | 8 GB (DDR5), 4800 MHz |
| BIOS verze | 2.22.0059, AMI, System Date 09/28/2026 |

**Příčina (potvrzeno):** disk neměl plně zasunutý/kontaktovaný konektor, přesně jak jsme flagovali jako neověřené v [verifikaci instalace SSD](../../01-before.order/SAPPHIRE/SAPPHIRE_EdgeAI_370/SSD/26-09-26.prevzeti-SSD/26-09-26.1609_Samsung990EVOPlus-2TB_verifikace-instalace.md) bod 3.1. Vyjmutí a znovuzasunutí problém odstranilo.

**Stav:** ✅ vyřešeno. Další krok: znovu nastartovat instalátor z USB, pokračovat „Detect disks" → „Partition disks", SSD by se teď měl objevit.
