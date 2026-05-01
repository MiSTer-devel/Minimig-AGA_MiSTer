#requires -Version 5.0
$ErrorActionPreference = "Stop"

# ModelSim Intel FPGA Starter Edition (bundled with Quartus 17.0) is truly license-free.
# Questa FE/FSE require a Siemens-issued license file even for free use.
$candidates = @(
    "C:\intelFPGA_lite\17.0\modelsim_ase\win32aloem\vsim.exe",
    "C:\altera_standard\25.1std\questa_fe\win64\vsim.exe"
)
$vsim = $null
foreach ($c in $candidates) {
    if (Test-Path -LiteralPath $c) { $vsim = $c; break }
}
if (-not $vsim) {
    Write-Error "No license-free vsim found. Tried: $($candidates -join ', ')"
    exit 2
}
Write-Host "Using vsim: $vsim" -ForegroundColor Cyan

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Push-Location $here
try {
    & $vsim -c -do "do run.do"
    $rc = $LASTEXITCODE
    if ($rc -eq 0) {
        Write-Host "tb_akiko_regs PASSED" -ForegroundColor Green
    } else {
        Write-Host "tb_akiko_regs FAILED (vsim exit $rc)" -ForegroundColor Red
    }
    exit $rc
} finally {
    Pop-Location
}
