# Gera chaves de licenca de TESTE (mock), no mesmo formato que o install-windows.ps1 aceita.
# Uso:  powershell -ExecutionPolicy Bypass -File gerar-chave-mock.ps1 -Produto FARM -Quantidade 5
# Quando existir o servidor de licencas, as chaves passam a ser emitidas e registradas por ele.
param([string]$Produto = 'FARM', [int]$Quantidade = 5)

$Alfa = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ'
function DigitoChave([string]$s) {
  $t = 0
  for ($i = 0; $i -lt $s.Length; $i++) { $t += ($Alfa.IndexOf($s[$i]) + 1) * ($i + 1) }
  return $Alfa[$t % $Alfa.Length]
}
$Produto = $Produto.ToUpper()
if ($Produto -notmatch '^[2-9A-HJ-NP-Z]{4}$') { throw 'Produto deve ter 4 letras (sem I e O), ex.: FARM' }
$rnd = New-Object System.Random
1..$Quantidade | ForEach-Object {
  $a = -join (1..4 | ForEach-Object { $Alfa[$rnd.Next($Alfa.Length)] })
  $b = -join (1..4 | ForEach-Object { $Alfa[$rnd.Next($Alfa.Length)] })
  "$Produto-$a-$b-$(DigitoChave ($Produto + $a + $b))"
}
