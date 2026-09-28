# Analýza manuálu SAPPHIRE Edge AI 300 series — číhá na nás něco?

Rozbor [Owner_Manual_Sapphire_EDGE_AI_300_series_V1_202511.pdf](./Owner_Manual_Sapphire_EDGE_AI_300_series_V1_202511.pdf) (Manual Rev 1.0, říjen 2025), 2026-09-24. Cíl: najít případná nemilá překvapení / omezení / podmínky před koupí a montáží. Souvisí s [přehledem 370](./SAPPHIRE_EdgeAI_370/26-09-23.2315_prehled-a-nezavisle-recenze.md).

## Verdikt: žádný dealbreaker ✅

Manuál je spíš uklidňující — potvrzuje tool-less upgrade RAM/SSD jako **dokumentovaný, očekávaný postup** (magnetické víko, bez nářadí). Ale jsou tam **3 věci k akci** (hlavně kolem SSD a RAM) a pár drobností.

## Nálezy podle důležitosti

| Závažnost | Nález | Dopad |
|---|---|---|
| 🟠 **středně — akce** | **SSD potřebuje teplopodložku (thermal pad), a nemusí být součástí SSD** | ovlivňuje nákup SSD |
| 🟠 **středně — akce** | **RAM pro dual-channel musí být identické moduly** (stejná značka, velikost, rychlost, typ čipů) | potvrzuje volbu párovaného kitu |
| 🟡 **pozor při montáži** | SO-DIMM jde jen v jedné orientaci — **násilí zničí paměť i desku** | opatrnost při instalaci |
| 🟡 drobnost | Provozní teplota **0–40 °C** | běžný pokoj OK |
| 🟡 drobnost | CMOS baterie (CR2032 s pigtailem) je **„irreplaceable"** | dlouhodobá poznámka |
| 🟢 potvrzeno OK | Upgrade RAM/SSD přes magnetické víko = dokumentovaný postup, neruší záruku | žádný problém |

## Detaily — na co si dát pozor

### 🟠 1. SSD: teplopodložka (thermal pad) — zkontrolovat při nákupu
Manuál (kap. 3-2) výslovně: *„Please check whether your SSD comes with thermal pads while purchasing, if not, please prepare thermal pads."* Teplopodložka je v kontaktu mezi SSD a horním víkem a **zajišťuje chlazení SSD**. 
→ **Akce při nákupu SSD:** vzít M.2 SSD **s teplopodložkou/heatspreaderem**, nebo dokoupit thermal pad zvlášť. Bez něj hrozí přehřívání/throttling SSD. (Doplňuje se to k dřívějšímu závěru: M.2 2280 NVMe PCIe Gen4.)

### 🟠 2. RAM: dual-channel jen s IDENTICKÝMI moduly
Manuál (kap. 3-3): *„make sure you always have an identical (same brand, same size, same speed and chip-type) DDR5 SO-DIMM pairs to ensure the most compatible and optimal performance."*
→ **Přímo potvrzuje naše doporučení párovaného kitu** ([Corsair 5200 CL44 kit](./SAPPHIRE_EdgeAI_370/RAM/26-09-24.1539_SAPPHIRE370_srovnani-RAM-vhodnost-Intel-AMD.md)). Kupovat 2× samostatný modul (Patriot / Kingston KCP z [doporučení 100mega](./SAPPHIRE_EdgeAI_370/RAM/26-09-24.1545_SAPPHIRE370_100mega-doporuceni-pameti.md)) je proti tomuhle rizikovější — párovaný kit má identičnost garantovanou z výroby. **Další bod pro Corsair kit.**

### 🟡 3. Orientace SO-DIMM — nenásilit
*„The SO-DIMM memory will ONLY fit in one correct orientation. If with incorrect orientation will cause permanent damage to both SO-DIMM memory and motherboard... DO NOT FORCE."*
→ Při instalaci vložit pod ~30° pod správným natočením; pokud nejde, netlačit. Standardní opatrnost, ale manuál to zdůrazňuje kvůli riziku zničení desky.

### 🟡 4. Provozní teplota 0–40 °C
Mini-PC je certifikované na okolní teplotu 0–40 °C. V běžném pokoji problém není; pozor jen na uzavřený/špatně větraný prostor nebo horké léto bez klimatizace.

### 🟡 5. CMOS baterie „irreplaceable"
Manuál uvádí CR2032 s pigtail konektorem a označuje ji jako **irreplaceable** (nevyměnitelná běžným způsobem). Dlouhodobá poznámka — až po letech CMOS baterie dojde, není to prostý swap knoflíkové baterie (potřeba díl s konektorem / servis). Pro nejbližší roky irelevantní.

## Co manuál naopak potvrdil (uklidňující)

- **Upgrade RAM/SSD je oficiální, tool-less postup** — magnetické víko sundáš rukou, uvnitř 2× SO-DIMM + M.2 2280 + M.2 2242 (třetí M.2 2230 = WLAN). **Neruší to záruku** (na rozdíl od „neautorizovaného servisu" hlubších zásahů). Při skládání víka pozor na značku „FRONT" na vnitřní straně.
- **Monitor 200 Hz cesta potvrzena výrobcem:** 2× USB-C 4.0 „with PD 3.0 and support **DP 1.4a display output**" → přes USB-C→DP na DP 1.4a vstup monitoru pojede 200 Hz (HDMI 2.1 na SAPPHIRE by šlo, ale monitor má jen HDMI 2.0b = 100 Hz). Sedí s [use-case analýzou](./SAPPHIRE_EdgeAI_370/26-09-24.1735_SAPPHIRE370_planovane-use-case-a-ulohy.md).
- **RAM specs potvrzeny:** max 96 GB (2×48), max 5600 MHz — náš cíl 64 GB (2×32) je bezpečně v mezích.
- **Napájení:** externí 19V/6,32A/120W adaptér (teplo zdroje mimo skříň). V balení navíc **4× napájecí kabel** (různé zástrčky) + VESA držák.
- **Barebone bez RAM a SSD** — potvrzeno (obojí dokupuješ, což už řešíme).

## Akční body

1. **SSD kupovat s teplopodložkou** (nebo dokoupit thermal pad) — jinak hrozí přehřívání SSD.
2. **RAM ideálně párovaný kit** (Corsair) — manuál explicitně chce identické moduly pro dual-channel.
3. **Při montáži**: SO-DIMM nenásilit (jen jedna orientace), víko skládat značkou „FRONT" dopředu, uzemnit se před sáhnutím dovnitř.
4. Provoz držet v prostředí do 40 °C okolní teploty.

## Zdroj

- [Owner's Manual PDF (interní)](./Owner_Manual_Sapphire_EDGE_AI_300_series_V1_202511.pdf)
