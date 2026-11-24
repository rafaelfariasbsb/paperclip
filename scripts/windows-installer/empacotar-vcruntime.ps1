# Gera o pacote com as DLLs do Visual C++ (x64) que o PostgreSQL embutido do Paperclip precisa,
# para o install-windows.ps1 copiar ao lado do postgres.exe sem pedir administrador (UAC).
#
# Rode num Windows x64 que ja tenha o "Microsoft Visual C++ 2015-2022 Redistributable (x64)"
# atualizado. Depois publique o .zip num Release do GitHub e preencha no install-windows.ps1:
#   $VcRuntimeZipUrl    = '<URL do asset no Release>'
#   $VcRuntimeZipSha256 = '<hash impresso por este script>'
#
# Licenca: estas DLLs sao "Distributable Code" do Visual Studio; a redistribuicao app-local e
# permitida a quem tem licenca do Visual Studio (ver os termos da sua edicao).

param([string]$Saida = (Join-Path (Get-Location) 'paperclip-vcruntime-x64.zip'))

$ErrorActionPreference = 'Stop'
$dlls = 'vcruntime140.dll', 'vcruntime140_1.dll', 'msvcp140.dll'
$sys  = Join-Path $env:SystemRoot 'System32'

if (-not [Environment]::Is64BitOperatingSystem -or -not [Environment]::Is64BitProcess) {
  throw 'Rode num PowerShell 64 bits (System32 precisa conter as DLLs x64).'
}

$tmp = Join-Path $env:TEMP ('vcruntime-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
  foreach ($d in $dlls) {
    $origem = Join-Path $sys $d
    if (-not (Test-Path $origem)) { throw "Nao encontrei $origem. Instale o VC++ Redistributable x64 e rode de novo." }
    $ver = (Get-Item $origem).VersionInfo.FileVersion
    Write-Host ("{0,-20} {1}" -f $d, $ver)
    Copy-Item $origem $tmp
  }
  if (Test-Path $Saida) { Remove-Item $Saida -Force }
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [IO.Compression.ZipFile]::CreateFromDirectory($tmp, $Saida)
} finally {
  Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

$hash = (Get-FileHash $Saida -Algorithm SHA256).Hash
Write-Host "`nPacote: $Saida"
Write-Host "SHA256: $hash"
