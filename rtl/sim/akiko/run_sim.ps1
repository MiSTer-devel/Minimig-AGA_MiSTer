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
    # M1 regression
    & $vsim -c -do "do run.do"
    $rc1 = $LASTEXITCODE
    if ($rc1 -eq 0) {
        Write-Host "tb_akiko_regs PASSED" -ForegroundColor Green
    } else {
        Write-Host "tb_akiko_regs FAILED (vsim exit $rc1)" -ForegroundColor Red
    }

    # M2 bench
    & $vsim -c -do "do run_txrx.do"
    $rc2 = $LASTEXITCODE
    if ($rc2 -eq 0) {
        Write-Host "tb_akiko_txrx_dma PASSED" -ForegroundColor Green
    } else {
        Write-Host "tb_akiko_txrx_dma FAILED (vsim exit $rc2)" -ForegroundColor Red
    }

    # M3 bench
    & $vsim -c -do "do run_bridge.do"
    $rc3 = $LASTEXITCODE
    if ($rc3 -eq 0) {
        Write-Host "tb_akiko_hps_bridge PASSED" -ForegroundColor Green
    } else {
        Write-Host "tb_akiko_hps_bridge FAILED (vsim exit $rc3)" -ForegroundColor Red
    }

    if ($rc1 -ne 0 -or $rc2 -ne 0 -or $rc3 -ne 0) { exit 1 }
    exit 0
} finally {
    Pop-Location
}
