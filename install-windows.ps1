# Paperclip - instalador "um comando" para Windows 10/11
# Uso (Win+R):  powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/rafaelfariasbsb/paperclip/windows-installer/install-windows.ps1 | iex"
# Faz: Node.js portatil (sem admin) -> Paperclip -> atalho na Area de Trabalho -> abre no navegador.

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# Pasta do programa e dos dados. Se o nome do usuario tiver acento/caractere especial,
# usa C:\Paperclip (o PostgreSQL embutido nao se da bem com caminhos nao-ASCII).
$Base = Join-Path $env:LOCALAPPDATA 'Paperclip'
if ($Base -match '[^\x20-\x7E]') { $Base = 'C:\Paperclip' }
$NodeDir = Join-Path $Base 'node'
$Url     = 'http://127.0.0.1:3100'
$env:PAPERCLIP_HOME = Join-Path $Base 'dados'

function Passo($t) { Write-Host "`n==> $t" -ForegroundColor Cyan }
function Falha($t) {
  Write-Host "`nERRO: $t" -ForegroundColor Red
  Write-Host 'Tire uma foto desta tela e envie para quem te passou o comando.' -ForegroundColor Yellow
  Read-Host 'Pressione ENTER para fechar'
  exit 1
}
# Abre o navegador (em segundo plano) assim que o servidor responder
function AbrirNavegadorQuandoPronto {
  $s = "for(`$i=0;`$i -lt 600;`$i++){try{Invoke-WebRequest '$Url/api/health' -UseBasicParsing -TimeoutSec 2 | Out-Null; Start-Process '$Url'; break}catch{Start-Sleep 2}}"
  $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($s))
  Start-Process powershell -WindowStyle Hidden -ArgumentList '-NoProfile','-EncodedCommand',$enc
}

try {
  Write-Host 'Instalando o Paperclip. Leva de 5 a 15 minutos. NAO feche esta janela.' -ForegroundColor Green
  New-Item -ItemType Directory -Force -Path $Base, $env:PAPERCLIP_HOME | Out-Null

  # 0) Se ja estiver rodando (reinstalacao), fecha para liberar os arquivos
  Get-Process node, postgres -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -like "$Base*" } | Stop-Process -Force -ErrorAction SilentlyContinue

  # 1) Node.js 24 portatil (x64; no Windows ARM roda emulado)
  $nodeExe = Join-Path $NodeDir 'node.exe'
  $precisaNode = $true
  try {
    if (Test-Path $nodeExe) {
      $v = (& $nodeExe --version).TrimStart('v').Split('.')
      if ([int]$v[0] -gt 24 -or ([int]$v[0] -eq 24 -and [int]$v[1] -ge 11)) { $precisaNode = $false }
    }
  } catch { $precisaNode = $true }
  if ($precisaNode) {
    Passo 'Baixando o Node.js 24 (nao precisa de administrador)'
    $rel = (Invoke-RestMethod 'https://nodejs.org/dist/index.json' -UseBasicParsing) |
      Where-Object { $_.version -like 'v24.*' -and $_.files -contains 'win-x64-zip' } |
      Sort-Object { [version]$_.version.TrimStart('v') } -Descending | Select-Object -First 1
    if (-not $rel) { Falha 'Nao encontrei a versao 24 do Node.js para download.' }
    $zip = Join-Path $env:TEMP "node-$($rel.version)-win-x64.zip"
    Invoke-WebRequest "https://nodejs.org/dist/$($rel.version)/node-$($rel.version)-win-x64.zip" -OutFile $zip -UseBasicParsing
    if (Test-Path $NodeDir) { Remove-Item $NodeDir -Recurse -Force }
    $tmp = Join-Path $Base 'node-tmp'
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
    Passo 'Descompactando o Node.js'
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::ExtractToDirectory($zip, $tmp)
    Move-Item (Get-ChildItem $tmp | Select-Object -First 1).FullName $NodeDir
    Remove-Item $tmp, $zip -Recurse -Force -ErrorAction SilentlyContinue
  }
  $env:Path = "$NodeDir;$env:Path"

  # 2) Componente Visual C++ da Microsoft (o banco embutido precisa). So pede permissao se faltar.
  $sys = "$env:SystemRoot\System32"
  if (-not ((Test-Path "$sys\vcruntime140.dll") -and (Test-Path "$sys\vcruntime140_1.dll") -and (Test-Path "$sys\msvcp140.dll"))) {
    Passo 'Instalando componente da Microsoft (Visual C++). Se o Windows perguntar, clique em SIM.'
    $vc = Join-Path $env:TEMP 'vc_redist.x64.exe'
    Invoke-WebRequest 'https://aka.ms/vs/17/release/vc_redist.x64.exe' -OutFile $vc -UseBasicParsing
    try { Start-Process $vc -ArgumentList '/install','/quiet','/norestart' -Verb RunAs -Wait }
    catch { Falha 'E preciso clicar em SIM na pergunta do Windows (ou pedir a senha de administrador a quem cuida do computador). Rode o comando de novo.' }
  }

  # 3) Paperclip (fica dentro da pasta do Node; .cmd evita bloqueio de politica do PowerShell)
  Passo 'Baixando e instalando o Paperclip (a parte mais demorada)'
  & (Join-Path $NodeDir 'npm.cmd') install -g paperclipai@latest --prefix "$NodeDir" --no-audit --no-fund --loglevel=error
  if ($LASTEXITCODE -ne 0) { Falha "A instalacao do Paperclip falhou (npm, codigo $LASTEXITCODE). Verifique a internet e rode o comando de novo." }
  $pc = Join-Path $NodeDir 'paperclipai.cmd'
  if (-not (Test-Path $pc)) { Falha 'O comando paperclipai nao foi encontrado apos a instalacao.' }

  # 4) Iniciador + atalho na Area de Trabalho (usa %~dp0: funciona com espacos/acentos no caminho)
  Passo 'Criando o atalho "Paperclip" na Area de Trabalho'
  $start = Join-Path $Base 'Iniciar-Paperclip.cmd'
  $cmdText = @'
@echo off
title Paperclip - NAO FECHE esta janela enquanto estiver usando
set "PATH=%~dp0node;%PATH%"
set "PAPERCLIP_HOME=%~dp0dados"
set PAPERCLIP_NO_BROWSER=1
start "" /min powershell -NoProfile -WindowStyle Hidden -Command "for($i=0;$i -lt 300;$i++){try{Invoke-WebRequest 'http://127.0.0.1:3100/api/health' -UseBasicParsing -TimeoutSec 2 | Out-Null; Start-Process 'http://127.0.0.1:3100'; break}catch{Start-Sleep 2}}"
call "%~dp0node\paperclipai.cmd" run
echo.
echo O Paperclip parou. Se apareceu algum erro acima, tire uma foto desta tela.
pause
'@
  ($cmdText -replace "`r?`n", "`r`n") | Set-Content -Path $start -Encoding ASCII

  $desktop = [Environment]::GetFolderPath('Desktop')
  $ws  = New-Object -ComObject WScript.Shell
  $lnk = $ws.CreateShortcut((Join-Path $desktop 'Paperclip.lnk'))
  $lnk.TargetPath       = $start
  $lnk.WorkingDirectory = $Base
  $lnk.IconLocation     = "$nodeExe,0"
  $lnk.Save()

  # 5) Primeira configuracao (banco, chaves) e ja deixa rodando
  Passo 'Configurando e iniciando o Paperclip. O navegador vai abrir sozinho.'
  $env:PAPERCLIP_NO_BROWSER = '1'
  AbrirNavegadorQuandoPronto
  Write-Host "`nPRONTO! Deixe esta janela aberta enquanto usar o Paperclip." -ForegroundColor Green
  Write-Host 'Nas proximas vezes: dois cliques no icone "Paperclip" da Area de Trabalho.' -ForegroundColor Green
  & $pc onboard --yes
  if ($LASTEXITCODE -ne 0) { Falha "O Paperclip parou com erro (codigo $LASTEXITCODE)." }
  Read-Host 'O Paperclip foi encerrado. Pressione ENTER para fechar'
} catch {
  Falha $_.Exception.Message
}
