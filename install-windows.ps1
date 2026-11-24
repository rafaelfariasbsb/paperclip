# Paperclip - instalador "um comando" para Windows 10/11
# Uso (Win+R):  powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/rafaelfariasbsb/paperclip/windows-installer/install-windows.ps1 | iex"
#
# Faz, sem pedir administrador (quando as DLLs do VC++ estao disponiveis):
#   Node.js portatil -> Paperclip -> DLLs do VC++ ao lado do PostgreSQL embutido ->
#   iniciador/parada escondidos -> atalhos -> inicia em segundo plano e abre o navegador.
# A janela do instalador fecha sozinha no fim; o Paperclip continua rodando escondido.
#
# Observacao: mantenha este arquivo somente em ASCII (o PowerShell 5.1 le scripts sem BOM como ANSI).

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# ---------------------------------------------------------------- configuracao
# Versao do Paperclip (fixe uma versao para instalacoes reproduziveis, ex.: '1.2.3').
$PaperclipVersion  = 'latest'
# Iniciar o Paperclip (em segundo plano) quando o usuario entrar no Windows.
$IniciarComWindows = $true
# Pacote com vcruntime140.dll, vcruntime140_1.dll e msvcp140.dll (x64), gerado por
# scripts/windows-installer/empacotar-vcruntime.ps1 e publicado num Release.
# Vazio = pula esta etapa e, se faltar no sistema, instala o VC++ (pede permissao/UAC).
$VcRuntimeZipUrl    = ''
$VcRuntimeZipSha256 = ''

# ---------------------------------------------------------------- licenca e templates (MOCK)
# Enquanto nao existir o servidor de licencas, a chave e validada localmente (formato + digito).
# Quando existir: preencha $LicencaApiUrl. O servidor deve responder ao POST {chave} com
# { "valida": true, "produto": "FARM", "zipUrl": "...", "sha256": "...", "versao": "1.0.0" }.
$LicencaApiUrl = ''
# Chave pode vir pronta (ex.: instalacao feita por um assistente de IA): $env:PAPERCLIP_CHAVE e $env:PAPERCLIP_NOME_EMPRESA
$Catalogo = @{
  'FARM' = @{
    Nome    = 'Farmacia - Retaguarda com IA'
    Versao  = '1.0.0'
    ZipUrl  = 'https://raw.githubusercontent.com/rafaelfariasbsb/paperclip/windows-installer/templates/farmacia-retaguarda-v1.0.0.zip'
    Sha256  = 'C752AF83D3E26A2B8384D31AB7047AB14DD4AB31860FB00C3E952734F1B5EBE6'
    EnvDados = 'FARMACIA_DADOS'
  }
}
# Python portatil (os scripts das skills usam python3; o Windows nao traz Python)
$PythonVersao = '3.12.10'

# ---------------------------------------------------------------- caminhos
# Se o nome do usuario tiver acento/caractere especial, usa C:\Paperclip
# (o PostgreSQL embutido nao se da bem com caminhos nao-ASCII).
$Base = Join-Path $env:LOCALAPPDATA 'Paperclip'
$NaRaiz = $Base -match '[^\x20-\x7E]'
if ($NaRaiz) { $Base = 'C:\Paperclip' }
$NodeDir  = Join-Path $Base 'node'
$DataDir  = Join-Path $Base 'dados'
$LogDir   = Join-Path $Base 'logs'
$Iniciar  = Join-Path $Base 'Iniciar-Paperclip.ps1'
$Parar    = Join-Path $Base 'Parar-Paperclip.ps1'
$PsExe    = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$VcDlls   = 'vcruntime140.dll', 'vcruntime140_1.dll', 'msvcp140.dll'
$PyDir    = Join-Path $Base 'python'
$EmpresaDados = Join-Path $Base 'empresa'
$LicencaArq   = Join-Path $Base 'licenca.json'

function Passo($t) { Write-Host "`n==> $t" -ForegroundColor Cyan }
function Falha($t) {
  Write-Host "`nERRO: $t" -ForegroundColor Red
  Write-Host "Registro da instalacao: $LogDir\instalacao.log" -ForegroundColor Yellow
  Write-Host 'Envie esse arquivo (ou uma foto desta tela) para quem te passou o comando.' -ForegroundColor Yellow
  try { Stop-Transcript | Out-Null } catch { }
  Read-Host 'Pressione ENTER para fechar'
  exit 1
}

# ---------------------------------------------------------------- scripts gerados
# Iniciador: sobe o Paperclip escondido (logs em logs\paperclip.log) e abre o navegador.
# Codigos de saida: 0 = respondendo, 1 = falhou, 2 = porta ocupada por outro programa.
$IniciarConteudo = @'
param([switch]$SemNavegador, [switch]$Silencioso, [int]$TimeoutSeg = 900)
$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'
$Base    = $PSScriptRoot
$NodeDir = Join-Path $Base 'node'
$LogDir  = Join-Path $Base 'logs'
$Log     = Join-Path $LogDir 'paperclip.log'
$Url     = 'http://127.0.0.1:3100'
$env:Path                 = "$NodeDir;$(Join-Path $Base 'python');$env:Path"
$env:PAPERCLIP_HOME       = Join-Path $Base 'dados'
$env:PAPERCLIP_NO_BROWSER = '1'

function Responde {
  try { Invoke-WebRequest "$Url/api/health" -UseBasicParsing -TimeoutSec 3 | Out-Null; return $true } catch { return $false }
}
function Aviso($texto) {
  if ($Silencioso) { Write-Host $texto; return }
  Add-Type -AssemblyName PresentationFramework
  [System.Windows.MessageBox]::Show($texto, 'Paperclip') | Out-Null
}
function Nossos { Get-Process node, postgres -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path -like "$Base\*" } }
function Abrir { if (-not $SemNavegador) { Start-Process $Url } }

if (Responde) { Abrir; exit 0 }

# Porta 3100 em uso por um programa que nao e o nosso?
$donos = @(Get-NetTCPConnection -LocalPort 3100 -State Listen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique)
foreach ($id in $donos) {
  $p = Get-Process -Id $id -ErrorAction SilentlyContinue
  if (-not ($p -and $p.Path -and $p.Path -like "$Base\*")) {
    Aviso 'A porta 3100 esta sendo usada por outro programa. Feche esse programa (ou reinicie o computador) e abra o Paperclip de novo.'
    exit 2
  }
}

$balao = $null
if (-not $Silencioso) {
  try {
    Add-Type -AssemblyName System.Windows.Forms
    $balao = New-Object System.Windows.Forms.NotifyIcon
    $balao.Icon = [System.Drawing.SystemIcons]::Information
    $balao.Visible = $true
    $balao.ShowBalloonTip(8000, 'Paperclip', 'Iniciando... o navegador abre sozinho em instantes.', 'Info')
  } catch { $balao = $null }
}

# So inicia se ainda nao houver um Paperclip nosso subindo.
if (-not (Nossos)) {
  New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
  if ((Test-Path $Log) -and (Get-Item $Log).Length -gt 10MB) { Move-Item $Log "$Log.old" -Force }
  $config = Join-Path $env:PAPERCLIP_HOME 'instances\default\config.json'
  if (Test-Path $config) { $acao = 'run' } else { $acao = 'onboard --yes --no-install-service' }
  $pc  = Join-Path $NodeDir 'paperclipai.cmd'
  $cmd = '/d /s /c ""' + $pc + '" ' + $acao + ' >> "' + $Log + '" 2>&1"'
  Start-Process -FilePath $env:ComSpec -ArgumentList $cmd -WindowStyle Hidden -WorkingDirectory $Base
}

$ok = $false
$fim = (Get-Date).AddSeconds($TimeoutSeg)
while ((Get-Date) -lt $fim) {
  if (Responde) { $ok = $true; break }
  if (-not (Nossos)) { Start-Sleep 3; if (-not (Nossos) -and -not (Responde)) { break } }
  if ($Silencioso) { Write-Host '.' -NoNewline }
  Start-Sleep 3
}
if ($Silencioso) { Write-Host '' }
if ($balao) { $balao.Dispose() }

if ($ok) { Abrir; exit 0 }
if ($Silencioso -and (Test-Path $Log)) {
  Write-Host '--- ultimas linhas de logs\paperclip.log ---'
  Get-Content $Log -Tail 30 | ForEach-Object { Write-Host $_ }
}
Aviso "O Paperclip nao iniciou. Envie o arquivo abaixo para quem te ajuda:`n$Log"
exit 1
'@

# Parada: encerra o Paperclip e desliga o PostgreSQL embutido de forma limpa.
$PararConteudo = @'
param([switch]$Silencioso)
$ErrorActionPreference = 'SilentlyContinue'
$Base   = $PSScriptRoot
$DbDir  = Join-Path $Base 'dados\instances\default\db'
function Nossos($nome) { Get-Process $nome -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path -like "$Base\*" } }

Nossos node | Stop-Process -Force
if (Test-Path (Join-Path $DbDir 'postmaster.pid')) {
  $pgctl = Get-ChildItem (Join-Path $Base 'node\node_modules') -Recurse -Filter pg_ctl.exe -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($pgctl) { & $pgctl.FullName stop -D $DbDir -m fast -w -t 30 *> $null }
}
Start-Sleep 1
Nossos postgres | Stop-Process -Force
if (-not $Silencioso) {
  Add-Type -AssemblyName PresentationFramework
  [System.Windows.MessageBox]::Show('O Paperclip foi encerrado.', 'Paperclip') | Out-Null
}
'@

function NovoAtalho($caminho, $script, $argsExtra, $icone, $descricao) {
  $ws  = New-Object -ComObject WScript.Shell
  $lnk = $ws.CreateShortcut($caminho)
  $lnk.TargetPath       = $PsExe
  $lnk.Arguments        = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$script`" $argsExtra".Trim()
  $lnk.WorkingDirectory = $Base
  $lnk.IconLocation     = $icone
  $lnk.Description      = $descricao
  $lnk.WindowStyle      = 7   # minimizado: reduz o "piscar" da janela
  $lnk.Save()
}

# Pasta fora do perfil (C:\Paperclip) herda do C:\ a permissao "Usuarios autenticados: Modificar":
# qualquer usuario do PC poderia trocar o node.exe ou o iniciador (que roda no login).
# Por isso: recusa pasta criada por outro usuario e deixa acesso so ao usuario, SYSTEM e Administradores.
# Usa SIDs (e nao nomes) porque os nomes mudam com o idioma e o do usuario pode ter acento.
function ProtegerPasta($pasta) {
  $eu = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
  if (Test-Path $pasta) {
    try { $dono = (Get-Acl $pasta).GetOwner([Security.Principal.SecurityIdentifier]).Value } catch { $dono = '' }
    if ($dono -notin @($eu, 'S-1-5-32-544', 'S-1-5-18')) {
      Falha "A pasta $pasta foi criada por outro usuario deste computador. Por seguranca, peca a quem cuida do computador para apaga-la e rode o comando de novo."
    }
  } else {
    New-Item -ItemType Directory -Path $pasta | Out-Null
  }
  & icacls $pasta /inheritance:r /grant:r "*${eu}:(OI)(CI)F" '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' /Q | Out-Null
  if ($LASTEXITCODE -ne 0) { Falha "Nao consegui proteger as permissoes da pasta $pasta (icacls, codigo $LASTEXITCODE)." }
}

# ---------------------------------------------------------------- licenca (mock) e template
$Alfa = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ'   # sem 0, 1, I, O (evita confusao ao digitar)
# Ha alguem para digitar? (instalacao rodada direto no terminal de um assistente de IA nao tem)
$Interativo = [Environment]::UserInteractive -and -not [Console]::IsInputRedirected
function DigitoChave([string]$s) {
  $t = 0
  for ($i = 0; $i -lt $s.Length; $i++) { $t += ($Alfa.IndexOf($s[$i]) + 1) * ($i + 1) }
  return $Alfa[$t % $Alfa.Length]
}
# Devolve $null (invalida) ou @{ Produto; Demo; Chave }
function ValidarChave([string]$chave) {
  $c = ($chave -replace '\s', '').ToUpperInvariant()
  if ($c -match '^DEMO-([A-Z]{4})$' -and $Catalogo.ContainsKey($Matches[1])) {
    return @{ Produto = $Matches[1]; Demo = $true; Chave = $c }
  }
  if ($LicencaApiUrl) {
    try {
      $r = Invoke-RestMethod $LicencaApiUrl -Method Post -ContentType 'application/json' -Body (@{ chave = $c } | ConvertTo-Json) -UseBasicParsing
      if ($r.valida) {
        $Catalogo[$r.produto] = @{ Nome = $r.nome; Versao = $r.versao; ZipUrl = $r.zipUrl; Sha256 = $r.sha256; EnvDados = $r.envDados }
        return @{ Produto = $r.produto; Demo = $false; Chave = $c }
      }
    } catch { Write-Host "Nao consegui falar com o servidor de licencas: $($_.Exception.Message)" -ForegroundColor Yellow }
    return $null
  }
  # MOCK: PROD-XXXX-XXXX-D
  if ($c -notmatch '^([A-Z]{4})-([2-9A-HJ-NP-Z]{4})-([2-9A-HJ-NP-Z]{4})-([2-9A-HJ-NP-Z])$') { return $null }
  if (-not $Catalogo.ContainsKey($Matches[1])) { return $null }
  if ((DigitoChave ($Matches[1] + $Matches[2] + $Matches[3])) -ne $Matches[4][0]) { return $null }
  return @{ Produto = $Matches[1]; Demo = $false; Chave = $c }
}
function PedirLicenca {
  if ($env:PAPERCLIP_CHAVE -eq 'NENHUMA') { return $null }
  if ($env:PAPERCLIP_CHAVE) {
    $l = ValidarChave $env:PAPERCLIP_CHAVE
    if (-not $l) { Falha 'A chave informada nao e valida. Confira e rode de novo.' }
    return $l
  }
  if (-not $Interativo) { return $null }
  Write-Host "`nSe voce comprou um modelo de empresa (template), digite a CHAVE abaixo." -ForegroundColor Cyan
  Write-Host 'Formato: FARM-XXXX-XXXX-X. Para testar sem chave: DEMO-FARM. Para instalar sem modelo: so aperte ENTER.'
  for ($i = 1; $i -le 3; $i++) {
    $digitado = Read-Host 'Chave'
    if (-not $digitado) { return $null }
    $l = ValidarChave $digitado
    if ($l) { return $l }
    Write-Host 'Chave invalida. Confira as letras e os tracos.' -ForegroundColor Yellow
  }
  Falha 'Chave invalida depois de 3 tentativas. Confira a chave com quem vendeu e rode de novo.'
}
function ImportarTemplate($lic, [string]$nomeEmpresa) {
  $item = $Catalogo[$lic.Produto]
  Passo "Instalando o modelo: $($item.Nome) v$($item.Versao)"
  $tmpBase = Join-Path $Base 'tmp'   # caminho sempre ASCII (curl.exe e PS 5.1)
  New-Item -ItemType Directory -Force -Path $tmpBase | Out-Null
  $zip = Join-Path $tmpBase "template-$($lic.Produto)-$($item.Versao).zip"
  Invoke-WebRequest $item.ZipUrl -OutFile $zip -UseBasicParsing
  if ($item.Sha256 -and (Get-FileHash $zip -Algorithm SHA256).Hash -ne $item.Sha256.ToUpper()) {
    Falha 'O arquivo do modelo veio corrompido. Rode o comando de novo.'
  }
  # pasta de dados do modelo (entrada = exportacoes do sistema, saida = relatorios)
  $dados = Join-Path $EmpresaDados $lic.Produto.ToLower()
  New-Item -ItemType Directory -Force -Path (Join-Path $dados 'entrada'), (Join-Path $dados 'saida') | Out-Null
  if ($lic.Demo) {
    $tmp = Join-Path $tmpBase "template-$($lic.Produto)-ex"
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::ExtractToDirectory($zip, $tmp)
    Get-ChildItem $tmp -Recurse -Filter *.csv | Where-Object { $_.DirectoryName -like '*dados-exemplo*' } |
      Copy-Item -Destination (Join-Path $dados 'entrada') -Force
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
  }
  $meta = @{
    include           = @{ company = $true; agents = $true; skills = $true; issues = $true; projects = $false }
    target            = @{ mode = 'new_company'; newCompanyName = $nomeEmpresa }
    collisionStrategy = 'rename'
    pauseAutomations  = $true
  }
  if ($item.EnvDados) { $meta.secretValues = @{ ($item.EnvDados) = $dados } }
  $meta = $meta | ConvertTo-Json -Depth 5 -Compress
  $metaArq = Join-Path $tmpBase 'import-meta.json'
  [IO.File]::WriteAllText($metaArq, $meta, (New-Object Text.UTF8Encoding($false)))
  $resp = Join-Path $tmpBase 'import-resp.json'
  $curl = Join-Path $env:SystemRoot 'System32\curl.exe'
  if (-not (Test-Path $curl)) { Falha 'Este Windows nao tem o curl.exe (precisa do Windows 10 versao 1803 ou mais novo). Atualize o Windows e rode de novo.' }
  $codigo = & $curl -s -o $resp -w '%{http_code}' -X POST 'http://127.0.0.1:3100/api/companies/import' `
    -F "package=@$zip;type=application/zip" -F "meta=<$metaArq"
  if ($codigo -ne '200') {
    $msg = if (Test-Path $resp) { Get-Content $resp -Raw } else { '' }
    Falha "Nao consegui importar o modelo (HTTP $codigo). $msg"
  }
  $r = Get-Content $resp -Raw -Encoding UTF8 | ConvertFrom-Json
  @{ produto = $lic.Produto; versao = $item.Versao; chave = $lic.Chave; demo = $lic.Demo; empresaId = $r.company.id
     empresa = $nomeEmpresa; dados = $dados; instaladoEm = (Get-Date).ToString('s') } |
    ConvertTo-Json | Set-Content -Path $LicencaArq -Encoding UTF8
  Remove-Item $tmpBase -Recurse -Force -ErrorAction SilentlyContinue
  Write-Host "Modelo instalado: empresa '$nomeEmpresa' com $(@($r.agents).Count) agentes (todos pausados)." -ForegroundColor Green
  Write-Host "Pasta de dados: $dados"
}

# ================================================================ instalacao
try {
  if ($NaRaiz) { ProtegerPasta $Base }
  New-Item -ItemType Directory -Force -Path $Base, $DataDir, $LogDir | Out-Null
  try { Start-Transcript -Path (Join-Path $LogDir 'instalacao.log') -Force | Out-Null } catch { }
  Write-Host 'Instalando o Paperclip. Leva alguns minutos. NAO feche esta janela.' -ForegroundColor Green
  Write-Host "Pasta: $Base"

  # Licenca: pergunta no inicio para a pessoa nao esperar o download e depois errar a chave
  $ja = $null
  if (Test-Path $LicencaArq) { try { $ja = Get-Content $LicencaArq -Raw | ConvertFrom-Json } catch { } }
  $licenca = $null; $nomeEmpresa = $null
  $novaChave = $env:PAPERCLIP_CHAVE -and $env:PAPERCLIP_CHAVE -ne 'NENHUMA' -and
    (($env:PAPERCLIP_CHAVE -replace '\s', '').ToUpperInvariant() -ne $ja.chave)
  if ($ja -and $ja.empresaId -and -not $ja.demo -and -not $novaChave) {
    Write-Host "Modelo ja instalado antes: $($ja.produto) v$($ja.versao) ($($ja.empresa)). Reinstalando so o Paperclip." -ForegroundColor Cyan
  } else {
    $licenca = PedirLicenca
    if ($licenca) {
      $nomeEmpresa = $env:PAPERCLIP_NOME_EMPRESA
      if (-not $nomeEmpresa -and $Interativo -and -not $env:PAPERCLIP_CHAVE) { $nomeEmpresa = Read-Host 'Nome da empresa (ex.: Drogaria Sao Jose)' }
      if (-not $nomeEmpresa) { $nomeEmpresa = 'Minha Empresa' }
      if ($licenca.Demo) { $nomeEmpresa = "$nomeEmpresa (DEMONSTRACAO)" }
    }
  }

  # 0) Reinstalacao: encerra o que estiver rodando para liberar os arquivos
  if (Test-Path $Parar) {
    & $PsExe -NoProfile -ExecutionPolicy Bypass -File $Parar -Silencioso | Out-Null
  } else {
    Get-Process node, postgres -ErrorAction SilentlyContinue |
      Where-Object { $_.Path -and $_.Path -like "$Base\*" } | Stop-Process -Force -ErrorAction SilentlyContinue
  }

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
    $nome = "node-$($rel.version)-win-x64.zip"
    $zip  = Join-Path $env:TEMP $nome
    Invoke-WebRequest "https://nodejs.org/dist/$($rel.version)/$nome" -OutFile $zip -UseBasicParsing

    # Confere a integridade com o SHASUMS256.txt oficial
    $sums = (Invoke-WebRequest "https://nodejs.org/dist/$($rel.version)/SHASUMS256.txt" -UseBasicParsing).Content
    $esperado = ($sums -split "`n" | Where-Object { $_ -match "\s$([regex]::Escape($nome))\s*$" } | Select-Object -First 1) -replace '\s.*$', ''
    $obtido = (Get-FileHash $zip -Algorithm SHA256).Hash
    if (-not $esperado -or $obtido -ne $esperado.ToUpper()) {
      Remove-Item $zip -Force -ErrorAction SilentlyContinue
      Falha 'O download do Node.js veio corrompido. Rode o comando de novo.'
    }

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

  # 1b) Python portatil (sem administrador) para os scripts das skills
  $pyExe = Join-Path $PyDir 'python.exe'
  if (-not (Test-Path $pyExe)) {
    Passo 'Baixando o Python portatil (usado pelos calculos dos agentes)'
    $pyZip = Join-Path $env:TEMP "python-$PythonVersao-embed-amd64.zip"
    Invoke-WebRequest "https://www.python.org/ftp/python/$PythonVersao/python-$PythonVersao-embed-amd64.zip" -OutFile $pyZip -UseBasicParsing
    if (Test-Path $PyDir) { Remove-Item $PyDir -Recurse -Force }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::ExtractToDirectory($pyZip, $PyDir)
    Remove-Item $pyZip -Force -ErrorAction SilentlyContinue
  }
  # os scripts chamam "python3"; no Windows o executavel se chama python.exe
  Copy-Item $pyExe (Join-Path $PyDir 'python3.exe') -Force
  $env:Path = "$PyDir;$env:Path"

  # 2) Paperclip (fica dentro da pasta do Node; .cmd evita bloqueio de politica do PowerShell)
  Passo 'Baixando e instalando o Paperclip (a parte mais demorada)'
  & (Join-Path $NodeDir 'npm.cmd') install -g "paperclipai@$PaperclipVersion" --prefix "$NodeDir" `
      --cache (Join-Path $Base 'npm-cache') --no-audit --no-fund --loglevel=error
  if ($LASTEXITCODE -ne 0) { Falha "A instalacao do Paperclip falhou (npm, codigo $LASTEXITCODE). Verifique a internet e rode o comando de novo." }
  $pc = Join-Path $NodeDir 'paperclipai.cmd'
  if (-not (Test-Path $pc)) { Falha 'O comando paperclipai nao foi encontrado apos a instalacao.' }

  # 3) Componente Visual C++ que o PostgreSQL embutido precisa.
  #    Preferencia: ja existe no sistema -> copia local ao lado do postgres.exe (sem UAC) -> instalador da Microsoft (UAC).
  $sys = Join-Path $env:SystemRoot 'System32'
  $temNoSistema = -not ($VcDlls | Where-Object { -not (Test-Path (Join-Path $sys $_)) })
  if (-not $temNoSistema) {
    $binDirs = @(Get-ChildItem (Join-Path $NodeDir 'node_modules') -Recurse -Filter postgres.exe -ErrorAction SilentlyContinue |
      Where-Object { $_.DirectoryName -like '*windows-x64*' } | Select-Object -ExpandProperty DirectoryName -Unique)
    $copiou = $false
    if ($VcRuntimeZipUrl -and $binDirs.Count -gt 0) {
      try {
        Passo 'Copiando componente da Microsoft (Visual C++) para a pasta do Paperclip'
        $vcZip = Join-Path $env:TEMP 'paperclip-vcruntime-x64.zip'
        $vcDir = Join-Path $Base 'vcruntime'
        Invoke-WebRequest $VcRuntimeZipUrl -OutFile $vcZip -UseBasicParsing
        if ($VcRuntimeZipSha256 -and (Get-FileHash $vcZip -Algorithm SHA256).Hash -ne $VcRuntimeZipSha256.ToUpper()) {
          throw 'hash do pacote VC++ nao confere'
        }
        if (Test-Path $vcDir) { Remove-Item $vcDir -Recurse -Force }
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [IO.Compression.ZipFile]::ExtractToDirectory($vcZip, $vcDir)
        Remove-Item $vcZip -Force -ErrorAction SilentlyContinue
        foreach ($d in $binDirs) {
          foreach ($dll in $VcDlls) { Copy-Item (Join-Path $vcDir $dll) -Destination $d -Force }
        }
        $copiou = $true
      } catch {
        Write-Host "Nao deu para usar a copia local ($($_.Exception.Message)). Vou usar o instalador da Microsoft." -ForegroundColor Yellow
      }
    }
    if (-not $copiou) {
      Passo 'Instalando componente da Microsoft (Visual C++). Se o Windows perguntar, clique em SIM.'
      $vc = Join-Path $env:TEMP 'vc_redist.x64.exe'
      Invoke-WebRequest 'https://aka.ms/vs/17/release/vc_redist.x64.exe' -OutFile $vc -UseBasicParsing
      try { Start-Process $vc -ArgumentList '/install', '/quiet', '/norestart' -Verb RunAs -Wait }
      catch { Falha 'E preciso clicar em SIM na pergunta do Windows (ou pedir a senha de administrador a quem cuida do computador). Rode o comando de novo.' }
    }
  }

  # 4) Iniciador, parada e atalhos
  Passo 'Criando os atalhos "Paperclip" e "Parar Paperclip" na Area de Trabalho'
  ($IniciarConteudo -replace "`r?`n", "`r`n") | Set-Content -Path $Iniciar -Encoding ASCII
  ($PararConteudo   -replace "`r?`n", "`r`n") | Set-Content -Path $Parar   -Encoding ASCII
  Remove-Item (Join-Path $Base 'Iniciar-Paperclip.cmd') -Force -ErrorAction SilentlyContinue  # versao antiga

  $desktop = [Environment]::GetFolderPath('Desktop')
  NovoAtalho (Join-Path $desktop 'Paperclip.lnk') $Iniciar '' "$nodeExe,0" 'Abrir o Paperclip'
  NovoAtalho (Join-Path $desktop 'Parar Paperclip.lnk') $Parar '' "$sys\shell32.dll,27" 'Encerrar o Paperclip'
  $startup = Join-Path ([Environment]::GetFolderPath('Startup')) 'Paperclip.lnk'
  if ($IniciarComWindows) {
    NovoAtalho $startup $Iniciar '-SemNavegador' "$nodeExe,0" 'Iniciar o Paperclip com o Windows'
  } else {
    Remove-Item $startup -Force -ErrorAction SilentlyContinue
  }

  # 5) Primeira configuracao (banco, chaves) e inicio em segundo plano
  Passo 'Configurando e iniciando o Paperclip (na primeira vez demora um pouco mais)'
  & $PsExe -NoProfile -ExecutionPolicy Bypass -File $Iniciar -Silencioso -SemNavegador
  $codigo = $LASTEXITCODE
  if ($codigo -eq 2) { Falha 'A porta 3100 esta sendo usada por outro programa. Feche-o (ou reinicie o computador) e rode o comando de novo.' }
  if ($codigo -ne 0) { Falha "O Paperclip nao iniciou. Detalhes em $LogDir\paperclip.log" }

  # 6) Modelo de empresa (template) comprado
  if ($licenca) { ImportarTemplate $licenca $nomeEmpresa }

  Write-Host "`nPRONTO! O Paperclip esta rodando e o navegador vai abrir." -ForegroundColor Green
  Write-Host 'Pode fechar esta janela. Nas proximas vezes: dois cliques no icone "Paperclip" da Area de Trabalho.' -ForegroundColor Green
  try { Stop-Transcript | Out-Null } catch { }
  Start-Process 'http://127.0.0.1:3100'
  Start-Sleep 10
} catch {
  Falha $_.Exception.Message
}
