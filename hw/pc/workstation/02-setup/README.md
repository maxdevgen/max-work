# SAPPHIRE Edge AI 370 — 02-setup (nástup na provoz)

Založeno 2026-09-27. Fáze **po** rozhodování a objednávkách (viz [01-before.order](../01-before.order/)) — od prvního zapnutí po plně nastavený stroj v provozu. Struktura inspirovaná repozitářem `C:\repos\Nuc14` (RUNBOOK.md + checklist.md + config/ + backup/), přizpůsobená SAPPHIRE.

**Toto je výchozí kostra, upřesníme ji společně.**

## Kam co patří

| Soubor / složka | Účel |
|---|---|
| [RUNBOOK.md](RUNBOOK.md) | Krok za krokem, jak stroj postavit — instalace, konfigurace, ověření. Číslované sekce. |
| [checklist.md](checklist.md) | Odškrtávací seznam zrcadlící sekce RUNBOOK.md, pro reálné provádění |
| `docs/` | Hlubší rozbor jednotlivých témat (partitioning, VM, GRUB dual-boot...), na které RUNBOOK odkazuje |
| `config/` | Snímky konfiguračních souborů k obnovení (fstab, apt zdroje, GRUB...) |
| `backup/` | Skripty pro export/zálohu konfigurace před případnou reinstalací |

## Vztah k 01-before.order

Rozhodnutí o hardwaru (SSD, RAM, chlazení, monitor, RAM kity) jsou hotová a zůstávají v [01-before.order/SAPPHIRE/SAPPHIRE_EdgeAI_370/](../01-before.order/SAPPHIRE/SAPPHIRE_EdgeAI_370/). Sem (02-setup) patří jen to, co se děje **od zapnutí stroje dál** — instalace, nastavení, provoz.

Klíčové odkazy zpět:

- [Instalační plán a stav objednávek](../01-before.order/SAPPHIRE/SAPPHIRE_EdgeAI_370/26-09-25.1513_SAPPHIRE370_instalacni-plan.md)
- [Plánované use-case a úlohy](../01-before.order/SAPPHIRE/SAPPHIRE_EdgeAI_370/26-09-24.1735_SAPPHIRE370_planovane-use-case-a-ulohy.md) (dva Debiany + VM, sekce 7)
- [Výběr a verifikace SSD](../01-before.order/SAPPHIRE/SAPPHIRE_EdgeAI_370/26-09-24.1803_SAPPHIRE370_SSD-vyber-a-thermal-pad.md)
- [Objednávka a verifikace RAM](../01-before.order/SAPPHIRE/SAPPHIRE_EdgeAI_370/RAM/26-09-26.2225.Objednavka.RAM.Mironet.verif.md)

## Vysoký nadhled — co se bude instalovat

Rozhodnuto zatím (viz use-case, sekce 7.4–7.6), **k upřesnění**:

- **Debian A** — hlavní systém, běžná práce (Docker, Claude Code, kompilace), a v něm **virtuální stroj (KVM/libvirt)** běžící souběžně s prací.
- **Debian B** — malá záloha (~30–50 GB) jen pro nouzové opravy, pokud se A rozbije. Neběží současně s A, startuje se zvlášť z GRUB menu.
- **/data** — sdílený oddíl mezi A a B (obrazy VM, projekty).
- **EFI** — jeden společný oddíl pro oba Debiany.

Verze OS: **Debian 13 „Trixie"** (kernel 6.12 → amdgpu pro Strix Point funguje rovnou, bez čekání na backports).
