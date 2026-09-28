# První úspěšný boot — Debian 13 „Trixie" na SAPPHIRE (2026-09-27)

Instalace dokončena bez dalších chyb po opravě WiFi výpadku (viz [problém 05](05-problem-select-and-install-software-selhalo.md)). GRUB bootloader nainstalován, stroj restartován, naběhl přímo do GNOME (screenshot — GNOME Activities overview, Debian spiral watermark, dock s Firefox/Files/dalšími výchozími aplikacemi).

## Shrnutí instalace

| # | Krok | Výsledek |
|---|---|---|
| 1 | Instalační médium | ✅ Debian 13.7.0 netinst, ověřený SHA256, Rufus GPT/UEFI |
| 2 | SSD detekce | ⚠→✅ nejdřív nedetekován, opraveno vyjmutím/zasunutím ([problém 02](02-problem-SSD-nedetekovan-v-instalatoru.md)) |
| 3 | Rozdělení disku | ✅ EFI 999.3 MB, `/` 500 GB, `/data` 1.2 TB, 339.4 GB rezerva ([postup 03](03-partitioning-krok-za-krokem.md)) |
| 4 | Síť během instalace | WiFi (MediaTek MT7922) — funguje rovnou, firmware je součástí netinst od Debianu 12 |
| 5 | Software | GNOME desktop + SSH server + standard utilities; jeden výpadek při stahování, opraveno retry ([problém 05](05-problem-select-and-install-software-selhalo.md)) |
| 6 | Aktualizace | „Install security updates automatically" (unattended-upgrades) |
| 7 | GRUB | nainstalován na `/dev/nvme0n1` |
| 8 | První boot | ✅ **úspěšný**, GNOME desktop naběhl |

## Stav RAM při této instalaci

Dočasný 8GB modul z NUC14 (jednokanálově). Výměna za 2× 32 GB Patriot Signature (dual channel) proběhne po vyzvednutí z Mironetu (1. 10. 2026) — viz [instalační plán](../../01-before.order/SAPPHIRE/SAPPHIRE_EdgeAI_370/26-09-25.1513_SAPPHIRE370_instalacni-plan.md).

## Další kroky (RUNBOOK §4 a dál)

- [ ] Přihlásit se, projít prvotní nastavení GNOME
- [ ] Ověřit síť (WiFi funguje; ověřit i kabelové 2,5G LAN)
- [ ] Ověřit monitor 3440×1440@200 Hz přes USB-C→DisplayPort
- [ ] SSH přístup zvenku
- [ ] Aktualizovat systém (`apt update && apt upgrade`)
- [ ] Pokračovat podle [RUNBOOK.md](../RUNBOOK.md) §4 a dál

## Q&A: Preferuje uživatel Xfce (jako na NUC14)? (2026-09-27)

**Zjištění:** NUC14 běží na **Xfce**, ne na neurčeném DE, jak bylo dřív napsáno jako otevřená otázka — potvrzeno z jeho `config/xfce4/xfconf/xfce4-panel.xml`. Uživatel je zvyklý na Xfce zkratku **Alt+F3** (Application Finder), která v GNOME není svázaná (GNOME má Super pro přehled aplikací, Alt+F2 pro "Run Command").

**Rozhodnutí:** nainstalovat **Xfce vedle GNOME** (`sudo apt install task-xfce-desktop`), výběr session na přihlašovací obrazovce (GDM). Nemusí se to řešit exkluzivně — obě prostředí koexistují bez konfliktu.

**Otevřeno:** GNOME byl doporučen kvůli lepší otestované podpoře Wayland s AMD grafikou (relevantní pro 200Hz USB-C→DP monitor a hotplug chování). Pokud uživatel nakonec zvolí Xfce natrvalo, poběží na X11 (Xfce Wayland podpora v Debianu 13 je experimentální) — X11 ovladač amdgpu je ale sám o sobě zralý, jen hotplug/změny rozlišení mohou být o něco méně hladké než na Wayland (viz dřívější diskuze u monitoru/PBP). K vyzkoušení a rozhodnutí po prvním použití obou.
