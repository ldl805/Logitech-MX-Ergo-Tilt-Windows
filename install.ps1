param(
    [switch]$Uninstall,
    [switch]$Invert,
    [int]$CooldownMs = 300
)

$ErrorActionPreference = "Stop"
$InstallDir = "$env:LOCALAPPDATA\MxErgoTiltRemap"
$ExePath = "$InstallDir\MxErgoTiltRemap.exe"
$TaskName = "MxErgoTiltRemap"

if ($Uninstall) {
    Write-Host "Stopping MxErgoTiltRemap..." -ForegroundColor Cyan
    Stop-Process -Name "MxErgoTiltRemap" -Force -ErrorAction SilentlyContinue

    Write-Host "Removing Scheduled Task..." -ForegroundColor Cyan
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

    $StartupShortcut = Join-Path ([Environment]::GetFolderPath('Startup')) "MxErgoTiltRemap.lnk"
    if (Test-Path $StartupShortcut) {
        Remove-Item $StartupShortcut -Force
    }

    if (Test-Path $InstallDir) {
        Remove-Item $InstallDir -Recurse -Force
    }

    Write-Host "Uninstalled successfully." -ForegroundColor Green
    exit 0
}

Write-Host "Building MxErgoTiltRemap..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

Stop-Process -Name "MxErgoTiltRemap" -Force -ErrorAction SilentlyContinue

$csc = Get-ChildItem "C:\Windows\Microsoft.NET\Framework64\v4*\csc.exe" | Select-Object -Last 1 -ExpandProperty FullName
if (-not $csc) {
    throw "Could not find built-in .NET C# compiler (csc.exe)."
}

$srcFile = Join-Path $PSScriptRoot "src\MxErgoTiltRemap.cs"
Copy-Item $srcFile "$InstallDir\MxErgoTiltRemap.cs" -Force

& $csc /target:winexe /optimize+ /out:$ExePath $srcFile | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Compilation failed."
}

$argsList = @("--cooldown=$CooldownMs")
if ($Invert) {
    $argsList += "--invert"
}
$argString = $argsList -join " "

Write-Host "Registering Scheduled Task ($TaskName)..." -ForegroundColor Cyan
$action = New-ScheduledTaskAction -Execute $ExePath -Argument $argString
$trigger = New-ScheduledTaskTrigger -AtLogOn
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero)

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
Start-ScheduledTask -TaskName $TaskName

Write-Host "MxErgoTiltRemap installed and started in the background!" -ForegroundColor Green
