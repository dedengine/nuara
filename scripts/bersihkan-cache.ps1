[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$rootProject = Split-Path -Parent $PSScriptRoot

if (Get-Process -Name 'nuara_api' -ErrorAction SilentlyContinue) {
    throw 'Backend Nuara masih berjalan. Hentikan cargo run terlebih dahulu, lalu jalankan skrip ini kembali.'
}

function Invoke-DiFolder {
    param(
        [Parameter(Mandatory)]
        [string] $Path,
        [Parameter(Mandatory)]
        [scriptblock] $Command
    )

    Push-Location $Path
    try {
        & $Command
        if ($LASTEXITCODE -ne 0) {
            throw "Perintah pembersihan gagal di $Path."
        }
    }
    finally {
        Pop-Location
    }
}

Write-Host 'Membersihkan cache kompilasi Rust...'
Invoke-DiFolder -Path (Join-Path $rootProject 'backend') -Command { cargo clean }

Write-Host 'Membersihkan cache Flutter Admin Web...'
Invoke-DiFolder -Path (Join-Path $rootProject 'flutter_admin_web') -Command { flutter clean }

Write-Host 'Membersihkan cache Flutter Mobile...'
Invoke-DiFolder -Path (Join-Path $rootProject 'flutter_mobile') -Command { flutter clean }

Write-Host 'Selesai. Source code, database, dan media upload tidak dihapus.' -ForegroundColor Green
