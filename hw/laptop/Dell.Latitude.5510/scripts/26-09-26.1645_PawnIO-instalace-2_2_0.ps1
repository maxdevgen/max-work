# Instalace ovladace PawnIO (potrebuje ho LibreHardwareMonitor pro cteni teplot, taktu v MHz a prikonu)
# Spusteni: jako SPRAVCE, Windows PowerShell:
#   powershell.exe -ExecutionPolicy Bypass -File .\26-09-26.1645_PawnIO-instalace-2_2_0.ps1
# Postup: 1) winget (namazso.PawnIO), 2) pri neuspechu PawnIO_setup.exe z oficialniho GitHubu namazso/PawnIO.Setup
# Log jde do OutDir (nazev podle fmt.m).

param(
    [string]$OutDir = 'C:\repos\max-work\hw\laptop\Dell.Latitude.5510\tests',
    [string]$SetupUrl = 'https://github.com/namazso/PawnIO.Setup/releases/download/2.2.0/PawnIO_setup.exe'
)

$ErrorActionPreference = 'Stop'
$stamp = Get-Date -Format 'yy-MM-dd.HHmm'
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }
$logPath = Join-Path $OutDir "${stamp}_PawnIO-instalace.log"
try { Start-Transcript -Path $logPath -Force | Out-Null } catch { }

function Test-PawnIO { $null -ne (Get-Service -Name 'PawnIO' -ErrorAction SilentlyContinue) }

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { throw 'Spust jako SPRAVCE.' }

if (Test-PawnIO) {
    Write-Host 'PawnIO uz je nainstalovany, nic nedelam.'
}
else {
    $ok = $false
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host 'Instaluji PawnIO pres winget...'
        & winget install --id namazso.PawnIO --exact --silent --accept-package-agreements --accept-source-agreements
        $ok = Test-PawnIO
    }
    if (-not $ok) {
        Write-Host 'winget neuspel nebo chybi, stahuji PawnIO_setup.exe z GitHubu...'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $exe = Join-Path $env:TEMP 'PawnIO_setup.exe'
        Invoke-WebRequest -Uri $SetupUrl -OutFile $exe -UseBasicParsing
        $sig = Get-AuthenticodeSignature $exe
        Write-Host "Podpis instalatoru: $($sig.Status), $($sig.SignerCertificate.Subject)"
        if ($sig.Status -ne 'Valid') { throw 'Instalator nema platny podpis, instalaci rusim.' }
        $p = Start-Process -FilePath $exe -ArgumentList '-install', '-silent' -Wait -PassThru
        Write-Host "Instalator skoncil s kodem $($p.ExitCode)"
    }
}

Write-Host ''
& sc.exe query PawnIO
if (Test-PawnIO) { Write-Host 'OK: PawnIO je nainstalovany.' } else { Write-Warning 'PawnIO se nepodarilo nainstalovat, viz log.' }
Write-Host "Log: $logPath"
try { Stop-Transcript | Out-Null } catch { }
