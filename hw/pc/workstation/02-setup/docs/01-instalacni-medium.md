# Příprava instalačního média — Debian 13 „Trixie" pro SAPPHIRE Edge AI 370

Založeno 2026-09-27. Návazuje na [RUNBOOK.md §3](../RUNBOOK.md). Provádí se na tomto Windows stroji (kde běží tahle session), USB flash disk pak putuje do SAPPHIRE.

## 1. Stav — co už na tomhle stroji je

| # | Co | Zjištěno |
|---|---|---|
| 1.1 | ISO na disku | `C:\Users\max.dev.1\Downloads\debian-13.6.0-amd64-netinst.iso` (~792 MB, staženo 9. 8. 2026 pro reinstalaci NUC14) |
| 1.2 | **Aktuální verze** | **Debian 13.7.0** vyšla 12. 9. 2026 (novější než lokální 13.6.0) |
| 1.3 | Nástroj na zápis USB | `C:\Users\max.dev.1\Downloads\rufus-4.15.exe` (staženo 6. 8. 2026) |
| 1.4 | Kontrola SHA256 lokálního souboru | `65273beed27b2df543b68b65630ba525cfbad8df2b12035732b2dff87d6664e7` *(ověřit shodu s oficiálním SHA256SUMS pro 13.6.0, pokud se použije)* |

**Doporučení: stáhnout čerstvou 13.7.0**, ne použít starou 13.6.0. Je to jen bugfix/bezpečnostní point-release (ne nový kernel), ale ušetří to část aktualizací po instalaci a je jistota, že se stahuje z oficiálního zdroje pro tenhle konkrétní účel.

## 2. Krok 1 — stažení ISO

- [ ] Stáhnout `debian-13.7.0-amd64-netinst.iso` z <https://www.debian.org/download> (odkaz na `cdimage.debian.org`, amd64, netinst)
- [ ] Stáhnout ze **stejné složky** soubor `SHA256SUMS` (a případně `SHA256SUMS.sign`)
- [ ] Uložit do `hw\pc\workstation\02-setup\` nebo do `Downloads` — kamkoliv, hlavní je ověřit součet níže

**Poznámka k firmwaru (WiFi/BT) — OPRAVENO 2026-09-27:** původně jsem tu psal, že netinst neobsahuje nesvobodný firmware a doporučoval instalovat po kabelu. **To byla zastaralá informace.** Od Debianu 12 (2023) obsahují oficiální instalační obrazy běžný nesvobodný firmware ve výchozím stavu (změna politiky projektu). **Potvrzeno v praxi:** WiFi (MediaTek MT7922) se na SAPPHIRE při instalaci 13.7.0 připojila bez problémů, žádný kabel nebyl potřeba.

## 3. Krok 2 — ověření integrity (doporučeno, ne povinné)

Windows PowerShell:

```powershell
certutil -hashfile "C:\cesta\k\debian-13.7.0-amd64-netinst.iso" SHA256
```

Výstup porovnat řádek po řádku se souborem `SHA256SUMS` (najít řádek s `debian-13.7.0-amd64-netinst.iso`). Musí se **přesně shodovat**.

- [x] SHA256 sedí — **ověřeno 2026-09-27**: `a7ef94ac2fb9a7fec454552abd629b7cc9d5155c886165a45649f5ce6167e355`, shoduje se s oficiálním `SHA256SUMS` pro `debian-13.7.0-amd64-netinst.iso`. Soubor uložen v `02-setup\downloads\debian-13.7.0-amd64-netinst.iso`.

## 4. Krok 3 — zápis na USB flash disk (Rufus)

### 4.0 Stažení Rufusu (znovu, čerstvá verze)

- [x] Stáhnout aktuální Rufus z oficiální stránky: <https://rufus.ie/cs/> — **hotovo 2026-09-27**, `rufus-4.15p.exe` (portable), uloženo do `02-setup\downloads\`
- [x] Ověřen SHA256: `84c8a437f8af89257524478489e5c85f1edf25f761d299e2bcde46ac0afbe106`, shoduje se s oficiálním součtem. Verze 4.15 je aktuální stabilní (30. 6. 2026), žádná novější nevyšla.
- [x] Starý `rufus-4.15.exe` (staženo 6. 8. 2026) se nepoužívá

⚠ **Destruktivní krok** — Rufus **smaže vše** na cílovém USB disku. Před spuštěním ověřit, že je vybraný **správný disk** (ne systémový, ne jiný s daty).

1. Zasunout USB flash disk (postačí 4 GB a víc)
2. Spustit `rufus-4.15p.exe`
3. **Zařízení:** vybrat správný USB disk (zkontrolovat velikost/název, ne omylem jiný disk)
4. **Boot selection:** vybrat staženou ISO (`debian-13.7.0-amd64-netinst.iso`)
5. **Schéma oddílů:** **GPT** (SAPPHIRE bootuje přes UEFI, ne legacy BIOS)
6. **Cílový systém:** **UEFI (non-CSM)**
7. Když Rufus nabídne „Write in ISO Image mode" vs. „DD Image mode" → zvolit **ISO Image mode** (standardní pro hybridní Debian ISO)
8. Spustit zápis, počkat na dokončení (obvykle pár minut)
9. Bezpečně vysunout USB disk

- [x] Nastavení v Rufusu zkontrolováno **2026-09-27** (screenshot): Device `DEBIAN 13_6 (E:) [32 GB]`, boot selection `debian-13.7.0-amd64-netinst.iso`, Partition scheme **GPT**, Target system **UEFI (non CSM)**, persistence 0, status READY — vše odpovídá plánu. Název zařízení naznačuje dřívější použití pro Debian 13.6 (pravděpodobně z NUC14) — **potvrzeno, že je to správný, zamýšlený disk k přepsání**.
- [ ] Kliknuto START, zvoleno **ISO Image mode** (ne DD Image mode)
- [ ] USB disk zapsán a vysunut

## 5. Krok 4 — boot na SAPPHIRE

- [ ] Zasunout USB do SAPPHIRE (kterýkoliv USB-A port)
- [ ] Zapnout, při startu vyvolat boot menu (obvykle **F7**, **F11** nebo **Del/Esc** pro vstup do BIOSu a výběr boot zařízení — **u tohoto konkrétního BIOSu klávesa neověřena**, sledovat nápovědu na obrazovce při startu)
- [ ] Vybrat USB disk jako boot zařízení (v UEFI módu, ne „Legacy")
- [ ] Naběhne instalátor Debianu

## 6. Krok 5 — v instalátoru (přehled, detail viz RUNBOOK §2–3)

- [ ] Připojit **kabelovou síť** (2,5G LAN) kvůli firmwaru a balíčkům přes síť
- [ ] Jazyk instalace / locale — anglicky s `en_US.UTF-8` (podle vzoru NUC14), případně `cs_CZ.UTF-8` navíc
- [ ] Hostname — k rozhodnutí (návrh: `sapphire370` nebo podobně)
- [ ] **Rozdělení disku: „Manual" / ruční**, NE „Guided" — kvůli plánu dvou Debianů + `/data` (viz [partitioning, RUNBOOK §2](../RUNBOOK.md))
- [ ] Výběr softwaru na konci instalace: **odškrtnout desktop environment**, pokud se GUI bude instalovat zvlášť podle plánu (k rozhodnutí, viz RUNBOOK §5); ponechat **SSH server** a **standard system utilities**

## Otevřené otázky

1. Přesná klávesa pro boot menu na SAPPHIRE (zjistí se při prvním pokusu)
2. Hostname a uživatelské jméno
3. Rozdělení disku — přesné velikosti (viz RUNBOOK §2, zatím neupřesněno)
