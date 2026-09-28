# Rozdělení disku — podrobný postup krok za krokem (Debian instalátor, manuální partitioning)

Založeno 2026-09-27. Disk `/dev/nvme0n1`, Samsung 990 EVO Plus 2 TB (2000 GB decimálně — instalátor počítá v decimálních GB/TB, ne binárních GiB). Plán vychází z [RUNBOOK §2](../RUNBOOK.md) a [use-case sekce 7.6](../../01-before.order/SAPPHIRE/SAPPHIRE_EdgeAI_370/26-09-24.1735_SAPPHIRE370_planovane-use-case-a-ulohy.md).

## Cílové rozdělení (tahle instalace)

| # | Velikost | Use as | Mount point | Poznámka |
|---|---:|---|---|---|
| 1 | 1 GB | EFI System Partition | (automaticky) | společný EFI pro budoucí Debian B |
| 2 | 500 GB | Ext4 | `/` | root Debianu A (tahle instalace) |
| 3 | 1160 GB | Ext4 | `/data` | sdílená data, obrazy VM |
| — | ~339 GB zbyde | **nedělat nic** | — | necháme jako FREE SPACE pro Debian B (~40 GB) a rezervu (~300 GB), řešíme až při druhé instalaci |

Obecné ovládání instalátoru: **Tab** = přesun mezi poli/tlačítky, **mezerník** = zaškrtnutí/výběr v seznamu, **Enter** = potvrzení/aktivace tlačítka. Velikost se zadává jako číslo s jednotkou bez mezery, např. `1GB`, `500GB` (decimální jednotky, tak jak to hlásí i instalátor).

---

## Partition 1 — EFI System Partition (1 GB)

**Ty jsi právě tady** (obrazovka "New partition size", nabízí max 2.0 TB):

1. Pole je už vybrané/podsvícené s hodnotou `2.0 TB` — prostě přepiš: napiš **`1GB`** (přepíše se tím celý obsah pole)
2. **Enter** (nebo Tab na `<Continue>` a Enter)
3. Pokud se zeptá **"Type for the new partition"** (Primary/Logical) → vybrat **Primary**, Enter. *(Na GPT disku se tahle otázka nemusí objevit vůbec — to je normální, pokračuj dál.)*
4. Pokud se zeptá **"Location for the new partition"** (Beginning/End) → vybrat **Beginning**, Enter
5. Objeví se obrazovka **"Partition settings"** se seznamem řádků, něco jako:
   ```
   Use as:              Ext4 journaling file system
   Mount point:         none
   Bootable flag:       off
   Done setting up the partition
   ```
6. Najet na řádek **"Use as:"**, Enter — otevře se seznam typů
7. V seznamu najít a vybrat **"EFI System Partition"**, Enter *(instalátor tím sám nastaví formát FAT32 a příslušný mount, žádný mount point ručně nezadávej)*
8. Zpátky na "Partition settings" — zkontrolovat, že řádek "Use as" teď ukazuje "EFI System Partition"
9. Najet na **"Done setting up the partition"**, Enter

✅ První oddíl hotový. Vrátíš se na hlavní přehled (Partition disks), kde uvidíš nový 1GB oddíl a pod ním zbylé FREE SPACE.

---

## Partition 2 — root Debianu A (500 GB, `/`)

1. Na hlavním přehledu najet šipkami na řádek **FREE SPACE** (ten teď ukazuje zbytek, cca 1999 GB), Enter
2. Vybrat **"Create a new partition"**, Enter
3. **New partition size** — přepsat na **`500GB`**, Enter
4. Primary (pokud se zeptá), Enter
5. Beginning (pokud se zeptá), Enter
6. **Partition settings**:
   - "Use as" by měl už být defaultně **"Ext4 journaling file system"** — pokud ano, nech být (nemusíš do něj vstupovat)
   - Najet na **"Mount point"**, Enter — otevře se seznam předdefinovaných (`/`, `/home`, `/tmp`, `/usr`, `/var`, ...)
   - Vybrat **`/`** (root), Enter
7. Najet na **"Done setting up the partition"**, Enter

✅ Druhý oddíl hotový (500 GB, `/`, ext4).

---

## Partition 3 — sdílená data (1160 GB, `/data`)

1. Na hlavním přehledu znovu najet na **FREE SPACE** (teď cca 1499 GB), Enter
2. **"Create a new partition"**, Enter
3. **New partition size** — napsat **`1160GB`**, Enter
4. Primary / Beginning (pokud se zeptá), Enter
5. **Partition settings**:
   - "Use as": nechat **Ext4 journaling file system** (default)
   - Najet na **"Mount point"**, Enter — v seznamu **není** `/data` předdefinovaný, proto dole vybrat **"Enter manually"** (nebo podobnou položku úplně dole seznamu)
   - Napsat **`/data`**, Enter
6. Najet na **"Done setting up the partition"**, Enter

✅ Třetí oddíl hotový (1160 GB, `/data`, ext4).

---

## Po vytvoření všech tří oddílů

Na hlavním přehledu bys teď měl vidět něco jako:

```
/dev/nvme0n1 - 2.0 TB Samsung SSD 990 EVO Plus 2TB
   #1   1.0 GB   EFI    /boot/efi
   #2   500 GB   ext4   /
   #3  1160 GB   ext4   /data
        339 GB   FREE SPACE
```

**Tady se zastav a pošli mi screenshot** tohohle přehledu, než půjdeš na "Finish partitioning and write changes to disk" — to poslední je nevratný krok (zapíše se na disk).

## Provedeno — skutečný výsledek (2026-09-27)

Postup proběhl přesně podle plánu výše, potvrzeno screenshoty z instalátoru v každém kroku:

| # | Velikost (skutečná) | Typ | Label | Mount point | Stav |
|---|---:|---|---|---|---|
| 1 | 999.3 MB (cíl 1 GB, rozdíl jen zarovnání na sektory) | ESP | EFI | (automaticky) | ✅ |
| 2 | 500.0 GB | ext4 | debian-a | `/` | ✅ |
| 3 | 1.2 TB (cíl 1160 GB) | ext4 | data-a | `/data` | ✅ |
| — | 339.4 GB | FREE SPACE | — | — | ✅ ponecháno nedotčené (Debian B + rezerva, řeší se při druhé instalaci) |

**Swap:** instalátor upozornil, že není nastavený žádný swap oddíl ("You have not selected any partitions for use as swap space"). **Vybráno `<No>`** — pokračovat bez swapu. Důvod: instalace základního systému swap nepotřebuje; s příchodem 64GB RAM kitu (1. 10. 2026) swap nebude potřeba trvale. Pokud by dočasných 8 GB RAM do té doby nestačilo, řešením je **swapfile** po instalaci (ne přepartitioning).

**Finish partitioning and write changes to disk:** potvrzeno `Yes` na "Write the changes to disks?" — **zápis proběhl, tenhle krok je nevratný a je hotový.**

Instalace pokračuje na "Install the base system".
