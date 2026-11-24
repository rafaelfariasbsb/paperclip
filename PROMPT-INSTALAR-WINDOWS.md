Quero instalar o programa Paperclip neste computador Windows. Não entendo de informática, então faça o máximo possível sozinho e fale comigo em português simples, sem termos técnicos.

## 1. Descubra como você consegue agir neste computador

Há três modos. Descubra o seu antes de fazer qualquer outra coisa:

- **Modo A: você roda comandos direto neste Windows.** Para ter certeza, rode `where.exe powershell`. Só é modo A se a resposta for um caminho do Windows, como `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe`. Se der erro ou "comando não encontrado", os seus comandos rodam em um ambiente isolado, fora deste computador, e você **não** está no modo A.
- **Modo B: você enxerga a tela e controla o mouse e o teclado ("usar o computador"), mas não roda comandos direto neste Windows.**
- **Modo C: você só conversa.**

No modo B, não digite nem cole nada na caixa "Executar", no PowerShell, no Prompt de Comando ou no Terminal. O aplicativo não deixa, e isso é uma proteção para mim. Não insista e não procure outro caminho para rodar o comando no meu lugar, como criar um arquivo e dar dois cliques nele. Colar o comando e apertar Enter é a parte que eu faço.

Se o seu modo falhar no meio, não insista: me avise em uma frase e continue pelo modo seguinte (A → B → C).

## 2. Antes de começar, me explique o que vai acontecer

Sua primeira mensagem para mim é esta explicação, curta e em linguagem simples, antes de abrir qualquer janela ou rodar a instalação. Diga, com as suas palavras:

1. **O que vai ser instalado.** O Paperclip, um programa que roda só neste computador e abre no navegador. Junto vem o Node.js, baixado do site oficial. Fica tudo em uma pasta só minha (`%LOCALAPPDATA%\Paperclip`), com dois ícones na Área de Trabalho, e o Paperclip passa a ligar sozinho quando o computador liga.
2. **Como você vai agir no meu computador.** Use o texto do seu modo:
   - Modo A: "Eu mesmo vou rodar a instalação neste computador. O aplicativo pode mostrar o comando e pedir a sua permissão antes. Pode permitir."
   - Modo B: "Eu vou olhar a sua tela por fotos e posso mexer no mouse e no teclado, então é normal ver o ponteiro andar sozinho. O aplicativo vai pedir a sua permissão para isso. Tudo o que estiver aberto na tela aparece para mim, então feche antes o que for particular, como banco, e-mail e conversas. Por segurança, o aplicativo não me deixa digitar comandos: colar uma linha e apertar Enter é com você, e o resto eu acompanho."
   - Modo C: "Eu não consigo mexer no seu computador. Vou te dizer o que fazer, um passo por vez."
3. **O que eu vou ver.** Uma janela azul com textos, por 5 a 15 minutos. Talvez o Windows pergunte se pode fazer alterações: a resposta é SIM, e só eu consigo clicar. No fim o navegador abre sozinho com o Paperclip.
4. **O que você não vai fazer.** Pedir senhas, abrir meus arquivos pessoais, mudar configurações de segurança do Windows ou instalar qualquer outra coisa.
5. **Como parar e como desfazer.** Para parar no meio, eu aperto o botão de parar do aplicativo ou fecho a janela azul. Para desfazer depois, é só te pedir: basta parar o Paperclip e apagar a pasta e os ícones dele.

No modo A, comece a instalação logo depois da explicação. Nos modos B e C, termine a explicação com o primeiro passo que eu preciso fazer e espere a minha resposta.

## 3. Instale

### Modo A: você faz tudo

1. Confirme que é Windows 10 ou 11, 64 bits. Se não for, pare e me explique.
2. Abra a instalação em uma janela nova e visível. Rode exatamente este comando no PowerShell:

   ```powershell
   Start-Process powershell -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-Command','irm https://raw.githubusercontent.com/rafaelfariasbsb/paperclip/windows-installer/install-windows.ps1 | iex'
   ```

   Se a sua ferramenta de comandos não for o PowerShell, rode a mesma linha dentro de `powershell -NoProfile -Command "..."`.
   Não rode o script dentro do seu próprio terminal: ele espera o servidor subir e pode levar vários minutos.
3. Me avise: "A instalação começou. Se o Windows perguntar se pode fazer alterações, clique em SIM. Não feche a janela azul até ela dizer PRONTO."
4. Espere o Paperclip responder com um comando só, que fica tentando sozinho por até 8 minutos. Assim o aplicativo me pede permissão uma vez, e não a cada tentativa. Dê a esse comando um tempo limite de pelo menos 9 minutos:

   ```powershell
   $ok = $false; $fim = (Get-Date).AddMinutes(8)
   while (-not $ok -and (Get-Date) -lt $fim) { try { $ok = (Invoke-WebRequest http://127.0.0.1:3100/api/health -UseBasicParsing -TimeoutSec 5).StatusCode -eq 200 } catch { }; if (-not $ok) { Start-Sleep 10 } }
   if ($ok) { 'respondeu' } else { 'ainda nao' }
   ```

   Se sair `ainda nao`, rode de novo, até 20 minutos no total.
5. Quando sair `respondeu`, confirme também que existem os atalhos `Paperclip.lnk` e `Parar Paperclip.lnk` na Área de Trabalho (`[Environment]::GetFolderPath('Desktop')`).

### Modo B: eu colo o comando, você acompanha pela tela

1. No fim da explicação, me peça estas três coisas:
   - "Aperte ao mesmo tempo a tecla do Windows (a do símbolo de janelinha) e a letra R. Vai abrir uma caixinha chamada Executar."
   - "Copie a linha abaixo inteira, cole na caixinha com Ctrl+V e aperte Enter:"

     ```
     powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/rafaelfariasbsb/paperclip/windows-installer/install-windows.ps1 | iex"
     ```

   - "Me diga 'abriu' quando aparecer uma janela azul com textos."
2. Depois que eu disser "abriu", o acompanhamento é seu. Olhe a tela a cada 30 segundos, por até 20 minutos, e leia o que a janela azul mostra. Não clique nem digite nela.
3. A pergunta do Windows sobre fazer alterações pode não aparecer para você. Se a janela azul falar em "Visual C++", me avise para clicar em SIM.
4. Deu certo quando a janela azul mostra PRONTO, o navegador abre em http://127.0.0.1:3100 e os ícones "Paperclip" e "Parar Paperclip" estão na Área de Trabalho. Confira os três pela tela. Não teste o endereço pela sua ferramenta de comandos: ela não enxerga este computador.
5. Se você não conseguir ver a janela azul, me pergunte o que está escrito nela.

### Modo C: você me guia

Me guie um passo por vez, esperando eu dizer "pronto" antes do próximo:

1. "Aperte ao mesmo tempo a tecla do Windows (a do símbolo de janelinha) e a letra R. Vai abrir uma caixinha chamada Executar."
2. "Copie esta linha inteira e cole na caixinha (botão direito → Colar, ou Ctrl+V). Depois aperte Enter:"

   ```
   powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/rafaelfariasbsb/paperclip/windows-installer/install-windows.ps1 | iex"
   ```

3. "Vai abrir uma janela azul com textos. Não feche até aparecer PRONTO. Se o Windows perguntar se pode fazer alterações, clique em SIM. Demora alguns minutos."
4. "Quando terminar, o navegador abre sozinho com o Paperclip e a janela azul pode ser fechada."

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
