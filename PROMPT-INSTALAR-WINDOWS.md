Quero instalar o programa Paperclip neste computador Windows. Não entendo de informática, então faça o máximo possível sozinho e fale comigo em português simples, curto e sem termos técnicos.

O Paperclip vai rodar dentro do **WSL2** (o Linux que roda dentro do Windows), que é o jeito suportado pelo projeto: o manual oficial instala em macOS, Linux ou WSL2. Não instale o Paperclip direto no Windows.

Use exatamente as versões deste roteiro: **Paperclip 2026.1117.0**, **Node 24** e **Claude Code 2.1.291**. O `install.sh` oficial dessa versão ainda instala o Node 22 e usa uma opção que a CLI não aceita, e o Claude Code 2.1.330 ou mais novo quebra o login da assinatura no Paperclip. Por isso os passos abaixo fazem o mesmo que o instalador oficial, com essas correções (registro em https://github.com/rafaelfariasbsb/paperclip/issues/1). Não troque nenhuma versão por uma mais nova.

## 1. Descubra onde você está

- **Modo A: você roda comandos direto neste Windows.** É o caso do app Claude na aba Code (`</>`) com o ambiente "Local". Confira rodando `where.exe wsl` na ferramenta PowerShell: só é modo A se a resposta for um caminho como `C:\Windows\System32\wsl.exe`.
- **Modo B: qualquer outro caso** (conversa normal do app, sessão na nuvem, ambiente Linux isolado). Me explique em até três passos curtos como abrir a aba Code (`</>`) com o ambiente "Local", e pare. Não tente rodar comandos no meu computador por outro caminho.

## 2. Primeira mensagem (modo A)

Me pergunte: "Qual modelo de empresa você quer instalar?
1. **Farmácia** – retaguarda de drogaria
2. **Condomínio** – apoio ao síndico
Se você comprou, me mande a **chave** (ela já diz qual é o modelo) e o **nome da sua empresa ou do condomínio**. Para só testar, responda **DEMO FARMÁCIA** ou **DEMO CONDOMÍNIO**. Se não quiser nenhum modelo agora, responda NÃO."

O modelo sai da chave pelo prefixo (`FARM-` farmácia, `COND-` condomínio) ou da palavra depois de DEMO. Se eu responder só "DEMO" ou só o número, pergunte o que faltar. Os modelos estão no **catálogo** da etapa 3.5.

Depois explique, com as suas palavras, em no máximo cinco linhas curtas:
- Vou ligar o "Linux do Windows" (WSL), instalar o Paperclip dentro dele e deixar um ícone na Área de Trabalho. Ele roda só neste computador e abre no navegador.
- Se o Windows perguntar se pode fazer alterações, clique em **SIM**. Talvez eu peça para **reiniciar o computador** uma vez.
- O aplicativo vai me pedir permissão para rodar comandos: pode permitir.
- Não vou pedir senhas nem mexer nos seus arquivos.

Espere a resposta e comece. Guarde a chave e não a repita em outras mensagens. Se eu disser DEMO, o nome da empresa é o que eu der (ou o nome padrão do catálogo) seguido de " (DEMONSTRACAO)".

## 3. Instalação (modo A)

Rode tudo pela ferramenta PowerShell. Cada etapa confere o estado antes de agir, então dá para recomeçar do início depois de um reinício sem estragar nada. Use tempo limite de pelo menos 10 minutos nos comandos longos. Se uma etapa falhar, leia o erro, tente corrigir uma vez e, se não der, vá para a seção 6.

**Como rodar um script no Linux:** os comandos Linux abaixo devem ser enviados assim:

```powershell
$OutputEncoding = New-Object Text.UTF8Encoding $false
$s = @'
...script bash...
'@
$s | wsl.exe -d Ubuntu -u <usuario> -- bash -c "sed '1s/^\xEF\xBB\xBF//' | tr -d '\r' > /tmp/pc-<usuario>.sh && bash /tmp/pc-<usuario>.sh"
```

Troque `<usuario>` nos três lugares (`root` ou `paperclip`). O `$OutputEncoding` e o `sed` tiram a marca invisível (BOM) que o PowerShell coloca no começo do texto, e o `tr` tira as quebras de linha do Windows. Sem isso a primeira linha (`set -e`) não vale e o script segue mesmo depois de um erro. Cada usuário usa o seu próprio arquivo em `/tmp`, porque o `paperclip` não pode sobrescrever o arquivo do `root`. Só considere uma etapa concluída se a última linha da saída for a palavra esperada (`PREPARADO`, `INSTALADO`).

Não rode comandos Linux com `wsl.exe ... bash -lc '...'` contendo aspas duplas: o PowerShell do Windows as remove e o comando quebra.

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
3. Se o Ubuntu **já existia** antes desta instalação, rode `wsl.exe -d Ubuntu -u root -- sh -c 'dpkg -l nodejs npm 2>/dev/null | grep ^ii'`. Se aparecer algo, me avise antes de seguir: a etapa 3.2 troca o Node do Ubuntu pelo Node 24, e programas que eu já uso nesse Linux podem ser afetados.

### 3.2 Preparar o Linux (como root)

```bash
set -e
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
id paperclip >/dev/null 2>&1 || useradd -m -s /bin/bash paperclip
echo 'paperclip ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-paperclip-install
chmod 440 /etc/sudoers.d/90-paperclip-install
grep -q '^systemd=true' /etc/wsl.conf 2>/dev/null || printf '\n[boot]\nsystemd=true\n' >> /etc/wsl.conf
export DEBIAN_FRONTEND=noninteractive
apt-get update -y && apt-get install -y curl ca-certificates python3
# Node 24 pela mesma fonte que o install.sh oficial usa (NodeSource)
if [ "$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)" -lt 24 ]; then
  curl -fsSL https://deb.nodesource.com/setup_24.x -o /tmp/nodesource-24.sh
  bash /tmp/nodesource-24.sh
  apt-get install -y nodejs
fi
node --version
# Claude Code fixo na 2.1.291 (as mais novas quebram o login da assinatura no Paperclip 2026.1117.0)
[ "$(claude --version 2>/dev/null | cut -d' ' -f1)" = "2.1.291" ] || npm install -g @anthropic-ai/claude-code@2.1.291
claude --version | grep -q '^2\.1\.291 '
echo PREPARADO
```

Envie com `-u root`. O `PATH` da segunda linha deixa de fora os programas do Windows, que o Ubuntu enxerga e que não servem aqui (o `node` e o `claude` do Windows, por exemplo). Depois:
1. Rode `wsl.exe -d Ubuntu -u root -- ps -p 1 -o comm=`. Se não responder `systemd`, rode `wsl.exe --terminate Ubuntu`, espere 10 segundos e confira de novo. Se o `/etc/wsl.conf` já tinha uma seção `[boot]` com `systemd=false`, corrija essa linha para `true`.
2. Com o systemd ativo, rode `wsl.exe -d Ubuntu -u root -- loginctl enable-linger paperclip`. Isso mantém o Paperclip rodando sem ninguém logado no Linux.

A liberação de `sudo` sem senha é só para a instalação: ela é removida na etapa 3.4.

### 3.3 Paperclip (como o usuário `paperclip`)

Antes, confira que a porta 3100 está livre no Windows: `netstat -ano | findstr LISTENING | findstr ":3100 "`. Se aparecer algo, é quase sempre um Paperclip antigo instalado direto no Windows: veja a seção 6 antes de seguir. Se a 3100 estiver ocupada, o Paperclip novo sobe na 3101 e os endereços deste roteiro deixam de funcionar.

```bash
set -e
# umask 002 faz o pacote oficial recusar o executavel do Copilot e a instalacao falhar sem erro (paperclipai/paperclip#20024)
umask 022
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"
cd "$HOME"
npx --yes paperclipai@2026.1117.0 install --yes --version 2026.1117.0
paperclipai onboard --yes --install-service
# Interface em portugues: troca so a pasta ui-dist do servidor oficial pela versao traduzida (mesma versao 2026.1117.0)
UI_TAG=ui-ptbr-2026.1117.0-8eea7ab25
UI_SHA=92893dfbb981729a5e9e1ac00c1c646da6b529e49c7a6b8a6db1a4b8423f2b12
UI_DIR="$HOME/.paperclip/cli/current/node_modules/@paperclipai/server/ui-dist"
paperclipai --version | grep -q '2026\.1117\.0'
curl -fsSL -o /tmp/ui-ptbr.tar.gz "https://github.com/rafaelfariasbsb/paperclip/releases/download/$UI_TAG/paperclip-ui-ptbr-2026.1117.0-8eea7ab25.tar.gz"
echo "$UI_SHA  /tmp/ui-ptbr.tar.gz" | sha256sum -c
[ -d "$UI_DIR.oficial" ] || cp -a "$UI_DIR" "$UI_DIR.oficial"
rm -rf "$UI_DIR.novo" && mkdir -p "$UI_DIR.novo" && tar -xzf /tmp/ui-ptbr.tar.gz -C "$UI_DIR.novo"
test -f "$UI_DIR.novo/index.html"
rm -rf "$UI_DIR" && mv "$UI_DIR.novo" "$UI_DIR" && rm -f /tmp/ui-ptbr.tar.gz
# O servico nao deixa o Claude Code se atualizar sozinho (ver a 2.1.291 na etapa 3.2)
mkdir -p ~/.config/systemd/user/paperclipai.service.d
printf '[Service]\nEnvironment=DISABLE_AUTOUPDATER=1\n' > ~/.config/systemd/user/paperclipai.service.d/claude-pin.conf
systemctl --user daemon-reload
systemctl --user restart paperclipai.service
# Conferencia final: so imprime INSTALADO se tudo estiver certo
node --version | grep -qE '^v(2[4-9]|[3-9][0-9])\.'
claude --version | grep -q '^2\.1\.291 '
paperclipai --version
grep -lq 'Cole aqui o código de autorização' "$UI_DIR"/assets/*.js
for i in $(seq 1 60); do curl -fsS -m 5 http://127.0.0.1:3100/api/health >/dev/null 2>&1 && break; sleep 5; done
curl -fsS -m 5 http://127.0.0.1:3100/api/health
echo
echo INSTALADO
```

Envie com `-u paperclip`. A interface em português vem da Release `ui-ptbr-2026.1117.0-8eea7ab25` do fork (só a pasta `ui-dist`, conferida pelo SHA-256). A original fica guardada em `ui-dist.oficial`: para voltar ao inglês, apague `ui-dist`, renomeie `ui-dist.oficial` para `ui-dist` e rode `systemctl --user restart paperclipai.service`. Se o Paperclip for atualizado para outra versão, a interface volta ao inglês até existir uma Release traduzida para essa versão. Não use a interface traduzida com outra versão do servidor. O Claude Code (`claude`) é pré-requisito dos agentes do Paperclip, conforme o manual do adaptador; o Claude Desktop não substitui. Se a última linha não for `INSTALADO`, veja a primeira linha com erro e rode os comandos da seção 6.

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

Se der `AINDA NAO`, rode como `paperclip` (com as mesmas linhas `export` do 3.3): `paperclipai service status`, `paperclipai service logs` e `paperclipai doctor`, e corrija pelo que aparecer.

### 3.5 Modelo de empresa (só se eu mandei chave ou DEMO)

Pule esta etapa se eu disse NÃO. A validação da chave ainda é de teste: qualquer chave no formato `PREFIXO-XXXX-XXXX-X`, com um prefixo do catálogo, serve. Prefixo desconhecido: diga que a chave não é de nenhum modelo disponível e pergunte de novo.

**Catálogo de modelos**

| Prefixo | Modelo | Nome padrão (DEMO) | Pasta no Windows | Variável |
|---|---|---|---|---|
| `FARM` | Farmácia – Retaguarda com IA v1.0.0 | Minha Farmácia | `C:\FarmaciaDados` | `FARMACIA_DADOS` |
| `COND` | Condomínio – Gestão com IA v1.2.0 | Meu Condomínio | `C:\CondominioDados` | `CONDOMINIO_DADOS` |

```powershell
$modelo = 'FARM'           # FARM ou COND, pela chave ou pela resposta DEMO
$demo   = $true            # $false se eu mandei uma chave
$nome   = '<EMPRESA>'      # ja com " (DEMONSTRACAO)" se for DEMO; sem apostrofos
$base = 'https://raw.githubusercontent.com/rafaelfariasbsb/paperclip/windows-installer/templates'
$catalogo = @{
  FARM = @{ Zip = "$base/farmacia-retaguarda-v1.0.0.zip"; Sha = 'C752AF83D3E26A2B8384D31AB7047AB14DD4AB31860FB00C3E952734F1B5EBE6'
            Dados = 'C:\FarmaciaDados'; Var = 'FARMACIA_DADOS'; Agentes = 8 }
  COND = @{ Zip = "$base/condominio-gestao-v1.2.0.zip"; Sha = 'EE896B05287A03680A691CBEC7B691E41D3A97898383904D5652D3FFDCC5D26D'
            Dados = 'C:\CondominioDados'; Var = 'CONDOMINIO_DADOS'; Agentes = 9 }
}
$m = $catalogo[$modelo]; if (-not $m) { throw "Modelo desconhecido: $modelo" }
$tmp = Join-Path $env:TEMP 'paperclip-modelo'
if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
$zip = Join-Path $tmp 'modelo.zip'
Invoke-WebRequest $m.Zip -OutFile $zip -UseBasicParsing
if ((Get-FileHash $zip -Algorithm SHA256).Hash -ne $m.Sha) { throw 'Modelo corrompido' }
$dados = $m.Dados
New-Item -ItemType Directory -Force -Path "$dados\entrada", "$dados\saida" | Out-Null
if ($demo) {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [IO.Compression.ZipFile]::ExtractToDirectory($zip, "$tmp\ex")
  Get-ChildItem "$tmp\ex" -Recurse -Filter *.csv | Where-Object { $_.DirectoryName -like '*dados-exemplo*' } | Copy-Item -Destination "$dados\entrada" -Force
}
$var = $m.Var; $dadosLinux = '/mnt/c/' + (Split-Path $dados -Leaf)
$meta = @{ include = @{ company = $true; agents = $true; skills = $true; issues = $true; projects = $false }
  target = @{ mode = 'new_company'; newCompanyName = $nome }; collisionStrategy = 'rename'; pauseAutomations = $true
  secretValues = @{ $var = $dadosLinux } } | ConvertTo-Json -Depth 5 -Compress
[IO.File]::WriteAllText("$tmp\meta.json", $meta, (New-Object Text.UTF8Encoding($false)))
$cod = & "$env:SystemRoot\System32\curl.exe" -s -o "$tmp\resp.json" -w '%{http_code}' -X POST http://127.0.0.1:3100/api/companies/import -F "package=@$zip;type=application/zip" -F "meta=<$tmp\meta.json"
$r = Get-Content "$tmp\resp.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$pref = (Invoke-RestMethod "http://127.0.0.1:3100/api/companies/$($r.company.id)").issuePrefix
"HTTP $cod - agentes: $(@($r.agents).Count) de $($m.Agentes) - prefixo: $pref"
Remove-Item $tmp -Recurse -Force
```

Espere `HTTP 200` e o número de agentes do catálogo. Guarde o prefixo (ex.: `MIN`): ele entra no endereço da seção 5. A pasta do modelo (`C:\FarmaciaDados` ou `C:\CondominioDados`) é a mesma que o Linux enxerga em `/mnt/c/...`: é nela que vão as planilhas e exportações do sistema. Para instalar **outro modelo** depois, mande o mesmo link de novo e responda com a outra chave ou DEMO: as etapas 3.1 a 3.4 já estarão feitas e só a 3.5 roda.

## 4. Quando terminar, me diga em linguagem simples

- que deu certo e o Paperclip abre pelo ícone **Paperclip** na Área de Trabalho (ou em http://127.0.0.1:3100);
- que ele liga sozinho com o computador e que aparece uma janelinha minimizada do Linux na barra de tarefas: **não feche essa janela**, ela mantém o Paperclip ligado;
- se instalei o modelo, qual foi e em que pasta vão as planilhas: `C:\FarmaciaDados\entrada` (farmácia: exportações do sistema da loja) ou `C:\CondominioDados\entrada` (condomínio: relatórios da administradora e extrato do banco em OFX);
- que o primeiro agente a ativar é o **Implantação**, que faz as perguntas de configuração.

## 5. Último passo: conectar a assinatura do Claude

Os agentes só trabalham depois que eu conectar a minha assinatura do Claude. Quem faz isso sou eu, com poucos cliques. Você não faz por mim: não clique em "Autorizar", não peça senha e não peça nem leia o código de autorização, que é secreto.

As telas deste passo estão em português, porque a interface traduzida foi instalada na etapa 3.3. O idioma segue o do navegador. Se aparecer em inglês, peça para eu abrir o menu da conta (canto de baixo à esquerda) e escolher **Português (Brasil)**, ou use os nomes em inglês entre parênteses abaixo. O restante do Paperclip pode ter partes em inglês. Um passo por vez, esperando eu dizer "pronto":

1. "Abra http://127.0.0.1:3100/<PREFIXO>/agents/all. É a lista dos agentes. Confira que o endereço começa com **127.0.0.1:3100**. Se você tiver outra aba do Paperclip aberta em outro endereço (por exemplo, 3101), feche: ela é de uma instalação antiga. No dia a dia, abra sempre pelo ícone **Paperclip** da Área de Trabalho."
2. "Marque a **caixinha do topo da lista**, ao lado de **Agente**, para selecionar todos. Embaixo aparece **Editar conexão e modelo** (*Edit connection & model*): clique. Abre a janela **Atualizar N agentes**: marque **Mudar conexão** se ela não estiver marcada."
3. "Clique em conectar uma conta. Abre a janela **Conectar conta** (*Connect account*). Clique no quadro **Claude**, com **Assinatura** (*Subscription*) embaixo, e depois no link **Entrar em Claude**. Vai abrir uma página da Anthropic, a empresa do Claude."
4. "Nessa página, entre com a conta da sua assinatura e clique em **Autorizar** (ou **Authorize**). Ela mostra um código: copie. Não precisa me mandar."
5. "Volte ao Paperclip, cole o código no campo **Cole aqui o código de autorização** e, se não andar sozinho, clique em **Enviar código** (*Submit code*). Depois clique em **Conectar** (*Connect*) e, por fim, em **Atualizar N agentes** (*Update N agents*; N é o número de agentes do modelo)."

Se aparecer **Este login expirou**, **O login não terminou** ou **Sign-in ended before the account was connected** (algumas mensagens vêm do servidor e continuam em inglês), peça para clicar em **Começar o login de novo** ou **Refazer login** e refazer os passos 3 a 5. Se ficar parado em **Preparando o login pelo navegador…** (*Preparing browser sign-in...*) ou ainda falhar, rode como `paperclip` (com os `export` do 3.3): `command -v python3; command -v claude; claude --version`. O login precisa dos dois, e o `claude` tem de estar em `/usr/bin` na versão **2.1.291**. Se a versão for outra, repita a etapa 3.2 e depois `systemctl --user restart paperclipai.service`. Se a tela disser **Failed to fetch** ou **Connection interrupted**, confira o endereço (deve ser a porta 3100) antes de qualquer outra coisa. Se algum botão não existir, me peça um print.

Por fim, lembre que os agentes vêm **pausados**: eles só começam a trabalhar quando eu clicar em **Retomar todos** (*Resume all*) no aviso do **Painel** do Paperclip.

## 6. Se der erro

- **Linux**: rode como `paperclip` (com os `export` do 3.3) `paperclipai doctor` e `paperclipai service logs`, e leia antes de me pedir print.
- **Porta 3100 ocupada**: pode ser uma instalação antiga do Paperclip direto no Windows. Procure `%LOCALAPPDATA%\Paperclip` ou `C:\Paperclip`. Se existir, me pergunte antes de mexer. Com o meu OK, pare essa instalação com o `Parar-Paperclip.ps1 -Silencioso` que fica nessa pasta, apague os atalhos dela (`Paperclip.lnk` na Área de Trabalho e na Inicialização, `Parar Paperclip.lnk`) e depois a pasta. Por fim, rode `systemctl --user restart paperclipai.service` como `paperclip` e confira que ele voltou para a 3100.
- **Instalação do Paperclip sai com erro sem mensagem** (só o aviso do `uuid`): é o problema de permissão do pacote oficial (paperclipai/paperclip#20024). Confira que a etapa 3.3 rodou com `umask 022` e repita.
- **Versões erradas**: `node --version` tem de ser 24 ou mais, e `claude --version` tem de ser 2.1.291. Se não forem, repita a etapa 3.2.
- **Internet**: rode a etapa de novo.
- Para começar do zero (só com o meu OK, porque apaga tudo o que está no Linux): `wsl.exe --unregister Ubuntu` e apague os atalhos `Paperclip.url` (Área de Trabalho) e `Paperclip (WSL).lnk` (Inicialização). Só faça isso se o Ubuntu foi criado por esta instalação.

Regras:
- Não instale nada além do WSL2/Ubuntu, do Node 24 (NodeSource), do Paperclip 2026.1117.0 e do Claude Code 2.1.291.
- Não peça senhas e não leia códigos de autorização.
- Não desligue antivírus nem mude configurações de segurança do Windows.
