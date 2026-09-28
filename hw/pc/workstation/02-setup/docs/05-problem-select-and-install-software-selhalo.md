# Problém: "Select and install software" selhalo (Installation step failed)

Zjištěno 2026-09-27, po kroku výběru softwaru (GNOME desktop + SSH server, viz [RUNBOOK §5](../RUNBOOK.md)). Instalace přes **WiFi** (MediaTek MT7922, funguje bez firmware problému — viz [oprava poznámky](01-instalacni-medium.md)).

## Chybová hláška

```
[!!] Select and install software
Installation step failed
An installation step failed. You can try to run the failing item again
from the menu, or skip it and choose something else. The failing step is:
Select and install software
<Continue>
```

## Pravděpodobná příčina

**Výpadek/nestabilita WiFi připojení** během stahování balíčků (18 %, 316 z 1380 souborů před selháním). Před chybou uživatel hlásil kolísající odhady zbývajícího času (30 min → 8 min), což může naznačovat nestabilní rychlost/spojení.

## Postup opravy

1. Enter na `<Continue>` → návrat do hlavního menu instalátoru
2. Znovu zvolit **"Select and install software"** — apt/tasksel typicky **pokračuje**, ne od nuly
3. Pokud selže opakovaně → **přepnout na kabelové 2,5G LAN** místo WiFi (stabilnější pro velké stahování)

## Stav

⏳ Čeká se na výsledek opakovaného pokusu.
