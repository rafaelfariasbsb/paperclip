Quero instalar o programa Paperclip neste computador Windows. Não entendo de informática, então faça o máximo possível sozinho e fale comigo em português simples, curto e sem termos técnicos.

O Paperclip vai rodar dentro do **WSL2** (o Linux que roda dentro do Windows), que é o jeito suportado pelo projeto: o manual oficial instala em macOS, Linux ou WSL2. Siga o instalador oficial (`https://paperclip.ing/install.sh`). Não instale o Paperclip direto no Windows.

## 1. Descubra onde você está

- **Modo A: você roda comandos direto neste Windows.** É o caso do app Claude na aba Code (`</>`) com o ambiente "Local". Confira rodando `where.exe wsl` na ferramenta PowerShell: só é modo A se a resposta for um caminho como `C:\Windows\System32\wsl.exe`.
- **Modo B: qualquer outro caso** (conversa normal do app, sessão na nuvem, ambiente Linux isolado). Me explique em até três passos curtos como abrir a aba Code (`</>`) com o ambiente "Local", e pare. Não tente rodar comandos no meu computador por outro caminho.

## 2. Primeira mensagem (modo A)

Me pergunte: "Você comprou um modelo de empresa? Se sim, me mande a **chave** (formato `FARM-XXXX-XXXX-X`) e o **nome da sua empresa**. Para só testar, responda DEMO. Se não tiver, responda NÃO."

Depois explique, com as suas palavras, em no máximo cinco linhas curtas:
- Vou ligar o "Linux do Windows" (WSL), instalar o Paperclip dentro dele e deixar um ícone na Área de Trabalho. Ele roda só neste computador e abre no navegador.
- Se o Windows perguntar se pode fazer alterações, clique em **SIM**. Talvez eu peça para **reiniciar o computador** uma vez.
- O aplicativo vai me pedir permissão para rodar comandos: pode permitir.
- Não vou pedir senhas nem mexer nos seus arquivos.

Espere a resposta e comece. Guarde a chave e não a repita em outras mensagens. Se eu disser DEMO, o nome da empresa é o que eu der (ou "Minha Empresa") seguido de " (DEMONSTRACAO)".

## 3. Instalação (modo A)

Rode tudo pela ferramenta PowerShell. Cada etapa confere o estado antes de agir, então dá para recomeçar do início depois de um reinício sem estragar nada. Use tempo limite de pelo menos 10 minutos nos comandos longos. Se uma etapa falhar, leia o erro, tente corrigir uma vez e, se não der, vá para a seção 6.

**Como rodar um script no Linux:** os comandos Linux abaixo devem ser enviados assim, para não quebrar as quebras de linha do Windows:

```powershell
$s = @'
...script bash...
'@
$s | wsl.exe -d Ubuntu -u <usuario> -- bash -c "tr -d '\r' > /tmp/pc.sh && bash /tmp/pc.sh"
```

### 3.1 WSL2 e Ubuntu

1. Rode `wsl.exe -l -v`.
   - Se aparecer uma distribuição chamada **Ubuntu** na versão **2**, vá para 3.2.
   - Se aparecer Ubuntu na versão 1, rode `wsl.exe --set-version Ubuntu 2`.
   - Se o WSL não estiver instalado ou não houver Ubuntu, rode (abre o "SIM" do Windows):
     ```powershell
     Start-Process wsl.exe -Verb RunAs -Wait -ArgumentList '--install','-d','Ubuntu','--no-launch'
     ```
     Depois rode `wsl.exe -l -v` de novo. Se ainda não aparecer Ubuntu, ou se a saída falar em reiniciar, diga: "Agora preciso que você **reinicie o computador**. Quando ele voltar, abra o Claude na aba Code de novo e mande a mesma mensagem com o link." Pare aqui.
   - Se falar em **virtualização desligada** (BIOS), explique que é uma configuração do computador que precisa de um técnico e pare.
2. Confira que o Ubuntu responde como administrador: `wsl.exe -d Ubuntu -u root -- echo ok`. Se pedir para criar usuário ou der erro de distribuição não registrada, rode `ubuntu.exe install --root` e confira de novo.

### 3.2 Preparar o Linux (como root)

```bash
set -e
id paperclip >/dev/null 2>&1 || useradd -m -s /bin/bash paperclip
echo 'paperclip ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-paperclip-install
chmod 440 /etc/sudoers.d/90-paperclip-install
grep -q '^systemd=true' /etc/wsl.conf 2>/dev/null || printf '\n[boot]\nsystemd=true\n' >> /etc/wsl.conf
export DEBIAN_FRONTEND=noninteractive
apt-get update -y && apt-get install -y curl ca-certificates python3
echo PREPARADO
```

Envie com `-u root`. Depois:
1. Rode `wsl.exe -d Ubuntu -u root -- ps -p 1 -o comm=`. Se não responder `systemd`, rode `wsl.exe --terminate Ubuntu`, espere 10 segundos e confira de novo. Se o `/etc/wsl.conf` já tinha uma seção `[boot]` com `systemd=false`, corrija essa linha para `true`.
2. Com o systemd ativo, rode `wsl.exe -d Ubuntu -u root -- loginctl enable-linger paperclip`. Isso mantém o Paperclip rodando sem ninguém logado no Linux.

A liberação de `sudo` sem senha é só para a instalação: ela é removida na etapa 3.4.

### 3.3 Paperclip e Claude Code (como o usuário `paperclip`), pelo manual oficial

```bash
set -e
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
export PATH="$HOME/.local/bin:$PATH"
cd "$HOME"
curl -fsSLO https://paperclip.ing/install.sh
curl -fsSLO https://paperclip.ing/install.sh.sha256
sha256sum -c install.sh.sha256
bash install.sh --no-prompt --no-onboard
command -v claude >/dev/null || sudo npm install -g @anthropic-ai/claude-code
claude --version
paperclipai onboard --yes --install-service
paperclipai service status
echo INSTALADO
```

Envie com `-u paperclip`. Se o `sha256sum -c` não responder `install.sh: OK`, **pare**: o arquivo baixado não é o oficial. O Claude Code (`claude`) é pré-requisito dos agentes do Paperclip, conforme o manual do adaptador; o Claude Desktop não substitui.

### 3.4 Remover a liberação de sudo e manter o Paperclip ligado

```powershell
wsl.exe -d Ubuntu -u root -- rm -f /etc/sudoers.d/90-paperclip-install
$wsl = Join-Path $env:SystemRoot 'System32\wsl.exe'
$sh  = New-Object -ComObject WScript.Shell
$ini = Join-Path ([Environment]::GetFolderPath('Startup')) 'Paperclip (WSL).lnk'
$l = $sh.CreateShortcut($ini); $l.TargetPath = $wsl; $l.Arguments = '-d Ubuntu -u paperclip --exec sleep infinity'; $l.WindowStyle = 7; $l.Description = 'Mantem o Paperclip ligado'; $l.Save()
$url = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Paperclip.url'
Set-Content -Path $url -Encoding ASCII -Value "[InternetShortcut]`r`nURL=http://127.0.0.1:3100/"
Start-Process $wsl -WindowStyle Minimized -ArgumentList '-d','Ubuntu','-u','paperclip','--exec','sleep','infinity'
$ok = $false; $fim = (Get-Date).AddMinutes(5)
while (-not $ok -and (Get-Date) -lt $fim) { Start-Sleep 5; try { $ok = (Invoke-WebRequest http://127.0.0.1:3100/api/health -UseBasicParsing -TimeoutSec 5).StatusCode -eq 200 } catch { } }
if ($ok) { 'PRONTO' } else { 'AINDA NAO' }
```

O WSL desliga o Linux quando nenhuma janela dele está aberta. O atalho na Inicialização abre uma janela minimizada que mantém o Linux (e o Paperclip) ligado, inclusive depois de reiniciar o Windows.

Se der `AINDA NAO`, rode como `paperclip` (com as mesmas três linhas `export` do 3.3): `paperclipai service status`, `paperclipai service logs` e `paperclipai doctor`, e corrija pelo que aparecer.

### 3.5 Modelo de empresa (só se eu mandei chave ou DEMO)

Pule esta etapa se eu disse NÃO. A validação da chave ainda é de teste: qualquer chave no formato `FARM-XXXX-XXXX-X` serve.

```powershell
$zipUrl = 'https://raw.githubusercontent.com/rafaelfariasbsb/paperclip/windows-installer/templates/farmacia-retaguarda-v1.0.0.zip'
$sha    = 'C752AF83D3E26A2B8384D31AB7047AB14DD4AB31860FB00C3E952734F1B5EBE6'
$demo   = $true            # $false se eu mandei uma chave
$nome   = '<EMPRESA>'      # ja com " (DEMONSTRACAO)" se for DEMO; sem apostrofos
$tmp = Join-Path $env:TEMP 'paperclip-modelo'; New-Item -ItemType Directory -Force -Path $tmp | Out-Null
$zip = Join-Path $tmp 'modelo.zip'
Invoke-WebRequest $zipUrl -OutFile $zip -UseBasicParsing
if ((Get-FileHash $zip -Algorithm SHA256).Hash -ne $sha) { throw 'Modelo corrompido' }
$dados = 'C:\FarmaciaDados'
New-Item -ItemType Directory -Force -Path "$dados\entrada", "$dados\saida" | Out-Null
if ($demo) {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [IO.Compression.ZipFile]::ExtractToDirectory($zip, "$tmp\ex")
  Get-ChildItem "$tmp\ex" -Recurse -Filter *.csv | Where-Object { $_.DirectoryName -like '*dados-exemplo*' } | Copy-Item -Destination "$dados\entrada" -Force
}
$meta = @{ include = @{ company = $true; agents = $true; skills = $true; issues = $true; projects = $false }
  target = @{ mode = 'new_company'; newCompanyName = $nome }; collisionStrategy = 'rename'; pauseAutomations = $true
  secretValues = @{ FARMACIA_DADOS = '/mnt/c/FarmaciaDados' } } | ConvertTo-Json -Depth 5 -Compress
[IO.File]::WriteAllText("$tmp\meta.json", $meta, (New-Object Text.UTF8Encoding($false)))
$cod = & "$env:SystemRoot\System32\curl.exe" -s -o "$tmp\resp.json" -w '%{http_code}' -X POST http://127.0.0.1:3100/api/companies/import -F "package=@$zip;type=application/zip" -F "meta=<$tmp\meta.json"
$r = Get-Content "$tmp\resp.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$pref = (Invoke-RestMethod "http://127.0.0.1:3100/api/companies/$($r.company.id)").issuePrefix
"HTTP $cod - agentes: $(@($r.agents).Count) - prefixo: $pref"
Remove-Item $tmp -Recurse -Force
```

Espere `HTTP 200` e 8 agentes. Guarde o prefixo (ex.: `MIN`): ele entra no endereço da seção 5. A pasta `C:\FarmaciaDados` é a mesma que o Linux enxerga como `/mnt/c/FarmaciaDados`: é nela que a farmácia vai colocar as planilhas do sistema.

## 4. Quando terminar, me diga em linguagem simples

- que deu certo e o Paperclip abre pelo ícone **Paperclip** na Área de Trabalho (ou em http://127.0.0.1:3100);
- que ele liga sozinho com o computador e que aparece uma janelinha minimizada do Linux na barra de tarefas: **não feche essa janela**, ela mantém o Paperclip ligado;
- se instalei o modelo, que as planilhas do sistema da farmácia vão na pasta `C:\FarmaciaDados\entrada`.

## 5. Último passo: conectar a assinatura do Claude

Os agentes só trabalham depois que eu conectar a minha assinatura do Claude. Quem faz isso sou eu, com poucos cliques. Você não faz por mim: não clique em "Autorizar", não peça senha e não peça nem leia o código de autorização, que é secreto.

A tela do Paperclip está em inglês: cite os botões com o nome em inglês e diga o que significam. Um passo por vez, esperando eu dizer "pronto":

1. "Abra http://127.0.0.1:3100/<PREFIXO>/agents/all. É a lista dos agentes."
2. "Marque a **caixinha do topo da lista**, ao lado de **Agent**, para selecionar todos. Embaixo aparece **Edit connection & model** (editar conexão e modelo): clique."
3. "Abre a janela **Connect account** (conectar conta). Clique no quadro **Claude – Subscription** (assinatura) e depois no link para entrar no Claude. Vai abrir uma página da Anthropic, a empresa do Claude."
4. "Nessa página, entre com a conta da sua assinatura e clique em **Autorizar** (ou **Authorize**). Ela mostra um código: copie. Não precisa me mandar."
5. "Volte ao Paperclip, cole o código no campo **Paste authorization code here** e, se não andar sozinho, clique em **Submit code**. Depois clique em **Connect** e, por fim, em **Update 8 agents** (atualizar os 8 agentes)."

Se aparecer **Sign-in ended before the account was connected**, **This sign-in expired** ou **Sign-in didn't finish**, peça para clicar em **Start sign-in again** ou **Retry sign-in** e refazer os passos 3 a 5. Se ainda falhar, rode como `paperclip`: `command -v claude && command -v python3`, porque o login precisa dos dois. Se algum botão não existir, me peça um print.

Por fim, lembre que os agentes vêm **pausados**: eles só começam a trabalhar quando eu clicar em **Resume all** (retomar todos) no painel do Paperclip.

## 6. Se der erro

- **Linux**: rode como `paperclip` (com os `export` do 3.3) `paperclipai doctor` e `paperclipai service logs`, e leia antes de me pedir print.
- **Porta 3100 ocupada**: pode ser uma instalação antiga do Paperclip direto no Windows. Procure `%LOCALAPPDATA%\Paperclip` ou `C:\Paperclip` e, se existir, me pergunte antes de remover.
- **Internet**: rode a etapa de novo.
- Para começar do zero (só com o meu OK, porque apaga tudo o que está no Linux): `wsl.exe --unregister Ubuntu` e apague os atalhos `Paperclip.url` (Área de Trabalho) e `Paperclip (WSL).lnk` (Inicialização). Só faça isso se o Ubuntu foi criado por esta instalação.

Regras:
- Não instale nada além do WSL2/Ubuntu, do Paperclip pelo instalador oficial e do Claude Code.
- Não peça senhas e não leia códigos de autorização.
- Não desligue antivírus nem mude configurações de segurança do Windows.
