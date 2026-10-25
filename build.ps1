$ErrorActionPreference = "Stop"

$repoRoot = $PSScriptRoot
$distDir = Join-Path $repoRoot "dist"
New-Item -ItemType Directory -Force -Path $distDir | Out-Null

Write-Host "1. Compiling MxErgoTiltRemap.exe..." -ForegroundColor Cyan
$csc = Get-ChildItem "C:\Windows\Microsoft.NET\Framework64\v4*\csc.exe" | Select-Object -Last 1 -ExpandProperty FullName
$srcFile = Join-Path $repoRoot "src\MxErgoTiltRemap.cs"
$exeOut = Join-Path $distDir "MxErgoTiltRemap.exe"

& $csc /target:winexe /optimize+ /out:$exeOut $srcFile
if ($LASTEXITCODE -ne 0) {
    throw "Failed to compile MxErgoTiltRemap.exe"
}

Write-Host "2. Building NSIS Installer..." -ForegroundColor Cyan
$makensis = Get-Command makensis.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
if (-not $makensis -and (Test-Path "C:\Program Files (x86)\NSIS\makensis.exe")) {
    $makensis = "C:\Program Files (x86)\NSIS\makensis.exe"
}

if ($makensis) {
    & $makensis (Join-Path $repoRoot "installer\installer.nsi")
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to build NSIS installer"
    }
    Write-Host "Successfully built release artifacts in $distDir" -ForegroundColor Green
} else {
    Write-Warning "NSIS (makensis.exe) not found. Only portable MxErgoTiltRemap.exe was built."
}
