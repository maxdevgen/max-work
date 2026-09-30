# RUNBOOK — SAPPHIRE Edge AI 370 nástup na provoz

Založeno 2026-09-27. **Kostra k upřesnění** — sekce jsou zatím nadpisy s odkazy na rozhodnutí z [01-before.order](../01-before.order/SAPPHIRE/SAPPHIRE_EdgeAI_370/), obsah (přesné příkazy) doplníme postupně. Číslování sekcí odpovídá [checklist.md](checklist.md).

Hardwarová část (osazení SSD a RAM) je z velké části hotová, viz [instalační plán](../01-before.order/SAPPHIRE/SAPPHIRE_EdgeAI_370/26-09-25.1513_SAPPHIRE370_instalacni-plan.md) — sem patří software od prvního zapnutí dál.

---

## §0. Před zapnutím — stav hardwaru

- SSD: Samsung 990 EVO Plus 2 TB, osazen ve slotu 2280 (viz [verifikace instalace](../01-before.order/SAPPHIRE/SAPPHIRE_EdgeAI_370/SSD/26-09-26.prevzeti-SSD/26-09-26.1609_Samsung990EVOPlus-2TB_verifikace-instalace.md))
- RAM: Patriot Signature 2× 32 GB DDR5-4800, objednáno (vyzvednutí 1. 10. 2026), do té doby provizorně 8GB modul z NUC14
- Monitor: MSI MAG 342CQRF E20 přes USB-C → DisplayPort (200 Hz; HDMI dá jen 100 Hz)

## §1. První spuštění a BIOS

- [ ] Ověřit v BIOSu: RAM detekována (kapacita), SSD detekován, ventilátor běží
- [ ] Prozkoumat výkonnostní profily a fan-curve
- [ ] Rychlost linky SSD (Gen4 x4) a S.M.A.R.T. základ — před instalací OS pokud to BIOS umí, jinak po instalaci

**Detail:** [kontrolní seznam verifikace SSD](../01-before.order/SAPPHIRE/SAPPHIRE_EdgeAI_370/26-09-24.1803_SAPPHIRE370_SSD-vyber-a-thermal-pad.md) sekce 13

## §1a. Příprava instalačního média

**Hotovo → viz [docs/01-instalacni-medium.md](docs/01-instalacni-medium.md).** Stažení ISO, ověření SHA256, zápis na USB přes Rufus (GPT/UEFI), boot na SAPPHIRE.

- [ ] Stáhnout Debian 13.7.0 netinst amd64, ověřit SHA256
- [ ] Zapsat na USB (Rufus, GPT, UEFI)
- [ ] Ověřit boot z USB na SAPPHIRE

## §2. Rozdělení disku (partitioning)

**Hotovo 2026-09-27** → viz [docs/03-partitioning-krok-za-krokem.md](docs/03-partitioning-krok-za-krokem.md) (plán + skutečný výsledek, potvrzeno screenshoty).

- [x] EFI oddíl — 999.3 MB, ESP, label „EFI" (společný, pro oba Debiany)
- [x] Debian A — root 500 GB, ext4, label „debian-a", mount `/`
- [x] `/data` — 1.2 TB, ext4, label „data-a", mount `/data` (obrazy VM, projekty)
- [x] Rezerva — 339.4 GB ponecháno jako FREE SPACE (pro Debian B ~40 GB + rezervu ~300 GB, řeší se při druhé instalaci)
- [x] Swap vynechán (upozornění instalátoru potvrzeno „No"); dočasně 8GB RAM do 1. 10., pak 64GB kit; případně doplnit swapfile po instalaci
- [x] „Write the changes to disks" potvrzeno — **zápis proběhl, nevratný krok hotový**

**Problém a oprava cestou:** SSD se před partitioningem neobjevoval ani v BIOSu, ani v instalátoru — vyřešeno vyjmutím a znovuzasunutím do slotu. Podrobně: [docs/02-problem-SSD-nedetekovan-v-instalatoru.md](docs/02-problem-SSD-nedetekovan-v-instalatoru.md).

## §3. Debian A — základní instalace

**Hotovo 2026-09-27** → viz [docs/06-prvni-boot-uspesny.md](docs/06-prvni-boot-uspesny.md) (shrnutí celé instalace + odkazy na řešené problémy).

- [x] Instalace Debian 13.7.0 „Trixie" netinst
- [x] Hostname, uživatel, locale, časové pásmo, klávesnice (proklikáno v instalátoru)
- [x] Root heslo vynecháno (sudo přes prvního uživatele, konzistentní s NUC14)
- [x] GNOME desktop + SSH server nainstalovány
- [x] GRUB nainstalován na `/dev/nvme0n1`
- [x] **První boot úspěšný — GNOME naběhlo**

## §4. Debian A — síť, SSH, zabezpečení

- [ ] SSH
- [ ] UFW / firewall pravidla
- [ ] 2FA (pokud relevantní, k rozhodnutí)

## §5. Debian A — GUI a ovladače

- [ ] Desktop prostředí (k výběru — X11 vs. Wayland, viz dřívější poznámky o Strix Point/amdgpu)
- [ ] Grafika (amdgpu), zvuk, WiFi/BT (MediaTek MT7922)
- [ ] Ověřit monitor 3440×1440@200 Hz přes USB-C→DP

## §6. Debian A — vývojářské nástroje

- [x] Google Chrome + VS Code + Git — skript připraven → [scripts/install-chrome-vscode.sh](scripts/install-chrome-vscode.sh), vzor podle NUC14 (`Nuc14/RUNBOOK.md` §7). Spuštění bez psaní příkazů: zkopírovat z USB myší → pravé tlačítko → Vlastnosti → Oprávnění → zaškrtnout "Povolit spuštění jako program" → dvojklik → "Spustit v terminálu" → napsat jen sudo heslo.
- [ ] Docker
- [ ] Claude Code (CLI)
- [ ] Ostatní podle potřeby (k doplnění)

## §7. Virtuální stroj (KVM/libvirt) v Debianu A

- [ ] Zapnout virtualizaci AMD (SVM) v BIOSu
- [ ] Instalace KVM/QEMU/libvirt
- [ ] Obraz VM do `/data/vm`
- [ ] Účel VM — k upřesnění (Windows kvůli firemní VPN Check Point? viz [VPN soubor](../01-before.order/SAPPHIRE/SAPPHIRE_EdgeAI_370/26-09-24.1829_SAPPHIRE370_firemni-VPN-CheckPoint-na-Debianu.md))

## §8. Debian B — záložní systém

- [ ] Minimální instalace (bez GUI nebo lehké), nástroje pro opravu (gparted, ssh)
- [ ] GRUB — zapnout `os-prober`, ověřit, že se oba Debiany nabízí při startu
- [ ] Ověřit: EFI se nepřepsal, Debian A stále bootuje

## §9. OBS a nahrávání

- [ ] Externí WD Purple přes USB pro nahrávání (ne na interní SSD)
- [ ] OBS Studio, nastavení nahrávání do MKV
- [ ] 9.1 Hardwarový enkodér (VAAPI, AMD Radeon 890M/VCN) — postup a zdůvodnění: [docs/26-09-28.1653_use-case-video-enkodovani-a-OBS.md §2](docs/26-09-28.1653_use-case-video-enkodovani-a-OBS.md#2-use-case-2--obs-studio-s-hardwarovým-enkodérem-na-sapphire)
  - 9.1.1 `sudo apt install -y mesa-va-drivers vainfo obs-studio` (Flatpak `com.obsproject.Studio` jako záloha, pokud repo verze chybí AV1/nové VAAPI funkce)
  - 9.1.2 `vainfo` — ověřit profily H.264/HEVC/AV1 s `VAEntrypointEncSlice`
  - 9.1.3 OBS → Settings → Output → Encoder → vybrat AV1/HEVC/H.264 (VAAPI, hardware)

## §10. Ověření use-case

- [ ] Vývoj: Docker, Claude Code, kompilace — svižnost
- [ ] OBS + video streamy v Chrome — HW enkód/dekód, plynulost, teploty/hlučnost
- [ ] Virtualizace — VM běží souběžně s prací
- [ ] Firemní VPN — test na Debianu, rozhoduje architekturu (Debian vs. Windows jako pracovní systém)

## §11. Zálohy a údržba

- [ ] Co a kam se zálohuje (k rozhodnutí)
- [ ] Aktualizace Debianu B (občasné nabootování a update)

---

## Otevřené otázky k upřesnění

1. Přesné velikosti oddílů (§2)
2. Desktop prostředí a X11 vs. Wayland (§5)
3. Přesný účel a OS uvnitř VM (§7)
4. Rozsah Debianu B — jen nouzové nástroje, nebo i GUI? (§8)
5. Strategie záloh (§11)
