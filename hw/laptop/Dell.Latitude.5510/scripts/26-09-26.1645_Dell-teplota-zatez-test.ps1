# Dell Latitude 5510 - mereni teploty CPU, taktu a prikonu pod zatezi (LibreHardwareMonitor)
# Spusteni: Windows PowerShell (powershell.exe, NE pwsh) jako SPRAVCE:
#   powershell.exe -ExecutionPolicy Bypass -File .\26-09-26.1645_Dell-teplota-zatez-test.ps1
# Faze: klid (IdleSec) -> zatez vsemi vlakny (LoadSec) -> dochlazeni (CoolSec)
# Vystup: CSV + souhrn v OutDir (nazvy podle fmt.m). Stahne LibreHardwareMonitor z GitHubu, pokud chybi.

param(
    [int]$IdleSec = 30,
    [int]$LoadSec = 180,
    [int]$CoolSec = 30,
    [int]$Workers = [Environment]::ProcessorCount,
    [int]$SampleSec = 2,
    [string]$OutDir = 'C:\repos\max-work\hw\laptop\Dell.Latitude.5510\tests',
    [string]$ToolDir = (Join-Path $env:LOCALAPPDATA 'LibreHardwareMonitor')
)

$ErrorActionPreference = 'Stop'
$stamp = Get-Date -Format 'yy-MM-dd.HHmm'
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }
$logPath = Join-Path $OutDir "${stamp}_Dell-teplota-zatez.log"
$csvPath = Join-Path $OutDir "${stamp}_Dell-teplota-zatez.csv"
$sumPath = Join-Path $OutDir "${stamp}_Dell-teplota-zatez-souhrn.txt"

try { Start-Transcript -Path $logPath -Force | Out-Null } catch { }

# 1) Prava spravce (ovladac pro cteni teplot jadra)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { throw 'Spust PowerShell jako SPRAVCE (pravy klik -> Spustit jako spravce).' }
if ($PSVersionTable.PSEdition -eq 'Core') { throw 'Pouzij Windows PowerShell (powershell.exe), ne pwsh.' }

# 2) Stazeni a rozbaleni LibreHardwareMonitor, pokud chybi
$dll = Get-ChildItem -Path $ToolDir -Recurse -Filter 'LibreHardwareMonitorLib.dll' -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $dll) {
    Write-Host 'Stahuji LibreHardwareMonitor...'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    New-Item -ItemType Directory -Path $ToolDir -Force | Out-Null
    $zip = Join-Path $ToolDir 'LibreHardwareMonitor.zip'
    $rel = Invoke-RestMethod -Uri 'https://api.github.com/repos/LibreHardwareMonitor/LibreHardwareMonitor/releases/latest' -Headers @{ 'User-Agent' = 'ps' }
    $asset = $rel.assets | Where-Object { $_.name -eq 'LibreHardwareMonitor.zip' } | Select-Object -First 1
    if (-not $asset) { throw 'V posledni verzi nenalezen soubor LibreHardwareMonitor.zip.' }
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip -UseBasicParsing
    Expand-Archive -Path $zip -DestinationPath $ToolDir -Force
    Get-ChildItem -Path $ToolDir -Recurse | Unblock-File
    $dll = Get-ChildItem -Path $ToolDir -Recurse -Filter 'LibreHardwareMonitorLib.dll' | Select-Object -First 1
    if (-not $dll) { throw 'LibreHardwareMonitorLib.dll nenalezena po rozbaleni.' }
}
Write-Host "Knihovna: $($dll.FullName)"
Get-ChildItem -Path $dll.DirectoryName -Filter '*.dll' | ForEach-Object {
    try { [void][Reflection.Assembly]::LoadFrom($_.FullName) } catch { }
}

# 3) Otevreni senzoru CPU
$computer = New-Object LibreHardwareMonitor.Hardware.Computer
$computer.IsCpuEnabled = $true
$computer.Open()
$cpu = $computer.Hardware | Where-Object { $_.HardwareType.ToString() -eq 'Cpu' } | Select-Object -First 1
if (-not $cpu) { throw 'CPU senzory nenalezeny.' }
Write-Host "CPU: $($cpu.Name)"

function Get-Sample {
    $cpu.Update()
    $temps = @(); $clocks = @(); $pkgTemp = $null; $pkgPower = $null; $load = $null
    foreach ($s in $cpu.Sensors) {
        if ($null -eq $s.Value) { continue }
        $t = $s.SensorType.ToString()
        if ($t -eq 'Temperature') {
            if ($s.Name -match 'Package') { $pkgTemp = [double]$s.Value } elseif ($s.Name -match 'Core') { $temps += [double]$s.Value }
        }
        elseif ($t -eq 'Clock' -and $s.Name -match 'Core #') { $clocks += [double]$s.Value }
        elseif ($t -eq 'Power' -and $s.Name -match 'Package') { $pkgPower = [double]$s.Value }
        elseif ($t -eq 'Load' -and $s.Name -match 'Total') { $load = [double]$s.Value }
    }
    $maxCore = $null; if ($temps.Count) { $maxCore = ($temps | Measure-Object -Maximum).Maximum }
    $avgClk = $null; if ($clocks.Count) { $avgClk = [math]::Round(($clocks | Measure-Object -Average).Average, 0) }
    [pscustomobject]@{ TempPackage = $pkgTemp; TempMaxCore = $maxCore; ClockAvgMHz = $avgClk; PowerPkgW = $pkgPower; LoadPct = $load }
}

$pc = $null
try { $pc = New-Object Diagnostics.PerformanceCounter('Processor Information', '% Processor Performance', '_Total'); [void]$pc.NextValue() } catch { Write-Warning 'Windows citac taktu neni dostupny.' }
$test = Get-Sample
if ($null -eq $test.TempPackage -and $null -eq $test.TempMaxCore) {
    Write-Warning 'Teplota, takt ani prikon z ovladace se nenacetly (chybi ovladac PawnIO?). Zmerim jen takt v % zakladniho taktu a zatizeni z Windows. Pro teploty pouzij HWiNFO (Sensors-only) nebo nainstaluj ovladac PawnIO.'
}

# 4) Faze mereni
$rows = New-Object System.Collections.Generic.List[object]
$sw = [Diagnostics.Stopwatch]::StartNew()
function Run-Phase([string]$name, [int]$seconds) {
    Write-Host "Faze: $name ($seconds s)"
    $end = $sw.Elapsed.TotalSeconds + $seconds
    while ($sw.Elapsed.TotalSeconds -lt $end) {
        $s = Get-Sample
        $clkPct = $null; if ($pc) { $clkPct = [math]::Round($pc.NextValue(), 0) }
        $row = [pscustomobject]@{
            TimeSec = [math]::Round($sw.Elapsed.TotalSeconds, 1); Phase = $name
            TempPackage = $s.TempPackage; TempMaxCore = $s.TempMaxCore
            ClockAvgMHz = $s.ClockAvgMHz; ClockPctBase = $clkPct; PowerPkgW = $s.PowerPkgW; LoadPct = $s.LoadPct
        }
        $rows.Add($row)
        Write-Host ("  {0,6}s  temp {1} C  clock {2} MHz ({5} % zakl.)  power {3} W  load {4} %" -f $row.TimeSec, ($row.TempPackage, $row.TempMaxCore -ne $null | Select-Object -First 1), $row.ClockAvgMHz, $row.PowerPkgW, $row.LoadPct, $row.ClockPctBase)
        Start-Sleep -Seconds $SampleSec
    }
}

$procs = @()
try {
    Run-Phase 'klid' $IdleSec

    # zatez: N procesu, kazdy pocita sqrt+sin ve smycce
    $end = (Get-Date).AddSeconds($LoadSec + 5).ToString('o')
    $code = "`$e=[datetime]'$end';`$x=0.0;while((Get-Date) -lt `$e){for(`$i=0;`$i -lt 200000;`$i++){`$x+=[math]::Sqrt(`$i)*[math]::Sin(`$i)}}"
    for ($i = 0; $i -lt $Workers; $i++) {
        $procs += Start-Process -FilePath 'powershell.exe' -ArgumentList '-NoProfile', '-WindowStyle', 'Hidden', '-Command', $code -PassThru -WindowStyle Hidden
    }
    Run-Phase 'zatez' $LoadSec
}
finally {
    foreach ($p in $procs) { try { if (-not $p.HasExited) { $p.Kill() } } catch { } }
}
Run-Phase 'dochlazeni' $CoolSec
$computer.Close()

# 5) CSV + souhrn
$rows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
function T($r) { if ($null -ne $r.TempPackage) { $r.TempPackage } else { $r.TempMaxCore } }
$lines = @()
$lines += "Dell Latitude 5510 - test zateze $stamp"
$lines += "CPU: $($cpu.Name), pracovni procesy: $Workers, zatez $LoadSec s"
foreach ($ph in 'klid', 'zatez', 'dochlazeni') {
    $r = $rows | Where-Object { $_.Phase -eq $ph }
    $tv = @($r | ForEach-Object { T $_ } | Where-Object { $null -ne $_ })
    if ($tv.Count) {
        $m = $tv | Measure-Object -Minimum -Average -Maximum
        $lines += ("{0,-11} teplota min {1:N0} / prumer {2:N1} / max {3:N0} C" -f $ph, $m.Minimum, $m.Average, $m.Maximum)
    } else { $lines += "$ph : teplota nenactena" }
}
$lc = @($rows | Where-Object { $_.Phase -eq 'zatez' -and $null -ne $_.ClockPctBase -and $_.ClockPctBase -gt 0 })
if ($lc.Count -ge 4) {
    $n2 = [math]::Max(2, [int]($lc.Count / 5))
    $f2 = ($lc | Select-Object -First $n2 | Measure-Object ClockPctBase -Average).Average
    $l2 = ($lc | Select-Object -Last $n2 | Measure-Object ClockPctBase -Average).Average
    $lines += ("Takt v % zakladniho taktu (Windows citac): na zacatku zateze {0:N0} %, na konci {1:N0} % (pokles {2:N0} %)" -f $f2, $l2, (100 * ($f2 - $l2) / $f2))
}
$ld = @($rows | Where-Object { $_.Phase -eq 'zatez' -and $null -ne $_.ClockAvgMHz })
if ($ld.Count -ge 4) {
    $n = [math]::Max(2, [int]($ld.Count / 5))
    $first = ($ld | Select-Object -First $n | Measure-Object ClockAvgMHz -Average).Average
    $last = ($ld | Select-Object -Last $n | Measure-Object ClockAvgMHz -Average).Average
    $lines += ("Takt na zacatku zateze {0:N0} MHz, na konci {1:N0} MHz (pokles {2:N0} %)" -f $first, $last, (100 * ($first - $last) / $first))
    $pw = @($ld | Where-Object { $null -ne $_.PowerPkgW })
    if ($pw.Count) { $lines += ("Prikon CPU pod zatezi: prumer {0:N1} W, max {1:N1} W" -f ($pw | Measure-Object PowerPkgW -Average).Average, ($pw | Measure-Object PowerPkgW -Maximum).Maximum) }
}
$lines | Set-Content -Path $sumPath -Encoding UTF8
Write-Host ''
$lines | ForEach-Object { Write-Host $_ }
Write-Host "CSV:    $csvPath"
Write-Host "Souhrn: $sumPath"
Write-Host "Log:    $logPath"
try { Stop-Transcript | Out-Null } catch { }
