@echo off
rem Dell Latitude 5510 - 1) instalace ovladace PawnIO (pokud chybi), 2) test teploty pod zatezi
rem Po dvojkliku se sam spusti jako spravce. Log, CSV a souhrn jdou do OUTDIR (zapisuji je skripty).
setlocal

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Spoustim jako spravce...
    powershell.exe -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "DIR=%~dp0"
set "OUTDIR=C:\repos\max-work\hw\laptop\Dell.Latitude.5510\tests"
if not exist "%OUTDIR%" mkdir "%OUTDIR%"

echo === Krok 1: ovladac PawnIO ===
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%DIR%26-09-26.1645_PawnIO-instalace-2_2_0.ps1" -OutDir "%OUTDIR%"
echo.
echo === Krok 2: test zateze (asi 4 minuty) ===
echo Zavri Teams, Chrome, VS Code a OBS pred pokracovanim.
pause

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%DIR%26-09-26.1645_Dell-teplota-zatez-test.ps1" -OutDir "%OUTDIR%"

echo.
echo Hotovo. Vysledky jsou ve slozce: %OUTDIR%
pause
