Quero instalar o programa Paperclip neste computador Windows. Não entendo de informática, então faça o máximo possível sozinho e fale comigo em português simples, curto e sem termos técnicos.

## 1. Descubra onde você está

- **Modo A: você roda comandos direto neste Windows.** É o caso do app Claude na aba Code (`</>`) com o ambiente "Local". Se o seu ambiente informa que a plataforma é Windows (win32), você está no modo A. Na dúvida, rode `where.exe powershell`: só é modo A se a resposta for um caminho como `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe`.
- **Modo B: qualquer outro caso.** Por exemplo, a conversa normal do app, ou uma sessão cujos comandos rodam na nuvem ou num ambiente Linux isolado.

Não digite nem cole nada na caixa "Executar", no PowerShell, no Prompt de Comando ou no Terminal pelo controle da tela. O aplicativo não deixa, e isso é uma proteção para mim. Fora do modo A, não procure outro caminho para rodar comandos no meu computador, como criar um arquivo e dar dois cliques nele.

## 2. Modo A: você instala tudo

1. Sua primeira mensagem é só esta explicação, com as suas palavras, em no máximo cinco linhas curtas. Depois dela, comece a instalação sem esperar a minha resposta:
   - Vou instalar o Paperclip, um programa que roda só neste computador e abre no navegador. Junto vem o Node.js, do site oficial. Aparecem dois ícones na Área de Trabalho e o Paperclip passa a ligar junto com o computador.
   - Eu mesmo vou rodar a instalação neste computador. O aplicativo vai me pedir permissão: pode permitir.
   - Vai abrir uma janela azul por 5 a 15 minutos. Não feche. Se o Windows perguntar se pode fazer alterações, clique em SIM.
   - Não vou pedir senhas, mexer nos seus arquivos nem mudar a segurança do Windows. Para parar, use o botão de parar aqui ou feche a janela azul.
2. Rode o bloco abaixo como um comando só, na ferramenta PowerShell, com tempo limite de pelo menos 9 minutos. Assim o aplicativo me pede permissão uma vez só. O bloco confere o Windows, abre a instalação numa janela própria e espera o Paperclip responder.

   ```powershell
   if ([Environment]::OSVersion.Version.Major -lt 10 -or -not [Environment]::Is64BitOperatingSystem) { 'WINDOWS INCOMPATIVEL' } else {
     Start-Process powershell -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-Command','irm https://raw.githubusercontent.com/rafaelfariasbsb/paperclip/windows-installer/install-windows.ps1 | iex'
     $ok = $false; $fim = (Get-Date).AddMinutes(8)
     while (-not $ok -and (Get-Date) -lt $fim) { Start-Sleep 10; try { $ok = (Invoke-WebRequest http://127.0.0.1:3100/api/health -UseBasicParsing -TimeoutSec 5).StatusCode -eq 200 } catch { } }
     $d = [Environment]::GetFolderPath('Desktop')
     if (-not $ok) { 'AINDA NAO' } elseif ((Test-Path "$d\Paperclip.lnk") -and (Test-Path "$d\Parar Paperclip.lnk")) { 'PRONTO' } else { 'SEM ATALHOS' }
   }
   ```

3. Conforme a resposta:
   - `PRONTO`: vá para a seção 4.
   - `AINDA NAO`: rode de novo só a espera e a verificação (da linha do `$ok = $false` até a do `if (-not $ok)`), até 20 minutos no total. Não abra a instalação outra vez.
   - `SEM ATALHOS`: o Paperclip abriu, mas faltam os ícones. Leia o registro (veja "Se der erro") e me explique.
   - `WINDOWS INCOMPATIVEL`: pare e me explique que o Paperclip precisa de Windows 10 ou 11, 64 bits.

## 3. Modo B: me leve para a aba Code

Daqui você não consegue instalar sozinho. Sua primeira mensagem é só isto, com as suas palavras:

> Consigo instalar tudo sozinho, mas não por esta conversa: aqui, por segurança, eu não rodo nada no seu computador. Faça assim:
> 1. No alto da janela, à esquerda, clique no botão `</>`.
> 2. No canto esquerdo, clique no botão de criar uma conversa nova.
> 3. Se aparecer um botão de pasta embaixo da caixa de mensagem, escolha "Documentos".
> 4. Cole a mesma mensagem que você me mandou e aperte Enter.
>
> Lá eu explico o que vou fazer e cuido do resto. Se não achar o botão `</>`, me diga "não achei".

Se você consegue ver a minha tela, use nos passos os nomes exatos dos botões que aparecem nela. Se você já está na aba Code, mas os comandos rodam na nuvem, troque os passos 1 e 2 por: "Crie uma conversa nova e, no primeiro botão embaixo da caixa de mensagem, escolha Local."

### Se eu disser "não achei" ou a aba Code não funcionar

Me guie pela caixa Executar, um passo por vez, esperando eu dizer "pronto" antes do próximo:

1. "Aperte ao mesmo tempo a tecla do Windows (a do símbolo de janelinha) e a letra R. Vai abrir uma caixinha chamada Executar."
2. "Clique no botão de copiar da linha abaixo, cole na caixinha com Ctrl+V e aperte Enter:"

   ```
   powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/rafaelfariasbsb/paperclip/windows-installer/install-windows.ps1 | iex"
   ```

3. "Vai abrir uma janela azul com textos. Não feche até aparecer PRONTO; leva de 5 a 15 minutos. Se o Windows perguntar se pode fazer alterações, clique em SIM."

Se você consegue ver a tela, avise antes do passo 1: "Vou acompanhar pela sua tela. Se o aplicativo pedir permissão, pode permitir: eu só olho, não clico. Feche antes o que for particular, como banco e e-mail." Depois do passo 3, olhe a tela a cada 30 segundos, por até 20 minutos, sem clicar nem digitar, e confira a palavra PRONTO, o navegador em http://127.0.0.1:3100 e os ícones na Área de Trabalho. Não teste o endereço pela sua ferramenta de comandos: ela não enxerga este computador. Se você não vê a tela, me pergunte o que apareceu.

## 4. Quando terminar, me diga em linguagem simples

- que deu certo e o navegador abriu em http://127.0.0.1:3100;
- que o Paperclip roda escondido, sem janela, e já liga sozinho quando o computador é ligado;
- que para abrir é só dar dois cliques no ícone "Paperclip" e, para desligar, no "Parar Paperclip".

## Se der erro ou passar de 20 minutos sem resposta

O registro completo fica em `%LOCALAPPDATA%\Paperclip\logs\` (`instalacao.log` e `paperclip.log`; ou em `C:\Paperclip\logs\`). No modo A, leia esses arquivos antes de pedir foto da tela.

- Se você consegue ver a tela, leia a mensagem em vermelho na janela. Se não, me peça para eu te mandar uma foto ou print dela.
- Erros comuns:
  - **Falha de internet ou download:** rode a instalação de novo.
  - **"É preciso clicar em SIM":** rode de novo e me avise para clicar em SIM.
  - **Porta 3100 ocupada:** outro programa está usando a porta. Feche-o ou reinicie o computador e rode de novo.
- Para reinstalar do zero: clique em "Parar Paperclip", apague a pasta `%LOCALAPPDATA%\Paperclip` (ou `C:\Paperclip`, se existir) e rode a instalação de novo.

Regras:
- Não instale nada além disso.
- Não peça senhas.
- Não mude configurações de segurança do Windows.
