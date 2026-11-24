Quero instalar o programa Paperclip neste computador Windows. Não entendo de informática, então faça o máximo possível sozinho e fale comigo em português simples, sem termos técnicos.

## Se você consegue executar comandos neste computador (PowerShell, terminal, "computer use" etc.)

Faça tudo você mesmo, nesta ordem:

1. Confirme que é Windows 10 ou 11, 64 bits. Se não for, pare e me explique.
2. Abra a instalação em uma janela nova e visível (ela fica aberta porque o Paperclip roda nela). Rode exatamente este comando no PowerShell:

   ```powershell
   Start-Process powershell -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-Command','irm https://raw.githubusercontent.com/rafaelfariasbsb/paperclip/windows-installer/install-windows.ps1 | iex'
   ```

   Não rode o script dentro do seu próprio terminal: ele espera o servidor subir e pode levar vários minutos.
3. Me avise: "A instalação começou. Se o Windows perguntar se pode fazer alterações, clique em SIM. Não feche a janela azul até ela dizer PRONTO."
4. Verifique a cada 30 segundos, por até 20 minutos, se o Paperclip respondeu:

   ```powershell
   try { (Invoke-WebRequest http://127.0.0.1:3100/api/health -UseBasicParsing -TimeoutSec 5).StatusCode } catch { 'ainda nao' }
   ```

5. Quando responder 200, confirme também que existem os atalhos `Paperclip.lnk` e `Parar Paperclip.lnk` na Área de Trabalho (`[Environment]::GetFolderPath('Desktop')`).
6. Me diga em linguagem simples:
   - que deu certo e o navegador abriu em http://127.0.0.1:3100;
   - que o Paperclip roda escondido, sem janela, e já liga sozinho quando o computador é ligado;
   - que para abrir é só dar dois cliques no ícone "Paperclip" e, para desligar, no "Parar Paperclip".

Se der erro, o registro completo fica em `%LOCALAPPDATA%\Paperclip\logs\` (`instalacao.log` e `paperclip.log`; ou em `C:\Paperclip\logs\`). Leia esses arquivos antes de pedir foto da tela.

Se der erro ou passar de 20 minutos sem resposta:
- Se você consegue ver a tela, leia a mensagem em vermelho na janela. Se não, me peça para eu te mandar uma foto ou print dela.
- Erros comuns:
  - **Falha de internet ou download:** rode o passo 2 de novo.
  - **"É preciso clicar em SIM":** rode de novo e me avise para clicar em SIM.
  - **Porta 3100 ocupada:** outro programa está usando a porta. Feche-o ou reinicie o computador e rode de novo.
- Para reinstalar do zero: clique em "Parar Paperclip", apague a pasta `%LOCALAPPDATA%\Paperclip` (ou `C:\Paperclip`, se existir) e repita o passo 2.

Regras:
- Não instale nada além disso.
- Não peça senhas.
- Não mude configurações de segurança do Windows.

## Se você NÃO consegue executar comandos (só conversa)

Me guie um passo por vez, esperando eu dizer "pronto" antes do próximo:

1. "Aperte ao mesmo tempo a tecla do Windows (a do símbolo de janelinha) e a letra R. Vai abrir uma caixinha chamada Executar."
2. "Copie esta linha inteira e cole na caixinha (botão direito → Colar, ou Ctrl+V). Depois aperte Enter:"

   ```
   powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/rafaelfariasbsb/paperclip/windows-installer/install-windows.ps1 | iex"
   ```

3. "Vai abrir uma janela azul com textos. Não feche até aparecer PRONTO. Se o Windows perguntar se pode fazer alterações, clique em SIM. Demora alguns minutos."
4. "Quando terminar, o navegador abre sozinho com o Paperclip e a janela azul pode ser fechada. O Paperclip continua rodando escondido."
5. "Nas próximas vezes, dê dois cliques no ícone Paperclip da Área de Trabalho. Para desligar, use o ícone Parar Paperclip."

Se aparecer texto em vermelho, me peça uma foto da tela e me ajude com as mesmas soluções da lista de erros acima.
