# ===============================================================================
# publish_and_update.ps1 - Script de Publicação e Atualização do Instalador
# Organização: Líbera EdTech | .NET 10 | WinUI 3 | Windows App SDK 1.7
# -----------------------------------------------------------------------------
# Requisitos:
#   - Publicação em modo Self-Contained e Single-File (win-x64)
#   - Remoção de código morto (Trimmed = true) para reduzir o tamanho
#   - Parada automática de instâncias anteriores antes da cópia
#   - Atualização do executável em C:\Programa_SintelAula\Programa\Programa_Completo\SintelAula\Testar .exe\SintelAulaInstaller.exe
# ===============================================================================

$ErrorActionPreference = "Stop"

# -- Caminhos do script ---------------------------------------------------------
$RaizProjeto    = $PSScriptRoot
$ProjInstalador = Join-Path $RaizProjeto "src\SintelAula.Installer\SintelAula.Installer.csproj"
$PastaSaida     = Join-Path $RaizProjeto "src\SintelAula.Installer\bin\Release\net10.0-windows10.0.19041.0\win-x64\publish"
$DestinoAbsoluto = "C:\Programa_SintelAula\Programa\Programa_Completo\SintelAula\Testar .exe"
$NomeExeFinal    = "SintelAulaInstaller.exe"
$CaminhoExeFinal = Join-Path $DestinoAbsoluto $NomeExeFinal

# -- Cores de output -----------------------------------------------------------
function Write-Header($text) { Write-Host "`n=== $text ===" -ForegroundColor Cyan }
function Write-Step($text)   { Write-Host "  -> $text" -ForegroundColor White }
function Write-Success($text){ Write-Host "  [OK] $text" -ForegroundColor Green }
function Write-Warning($text){ Write-Host "  [AVISO] $text" -ForegroundColor Yellow }
function Write-Failure($text){ Write-Host "  [ERRO] $text" -ForegroundColor Red }

$timer = [System.Diagnostics.Stopwatch]::StartNew()

# -------------------------------------------------------------------------------
Write-Header "ETAPA 1 - Validação Inicial"

if (-not (Test-Path $ProjInstalador)) {
    Write-Failure "Projeto não encontrado: $ProjInstalador"
    exit 1
}
Write-Success "Projeto do instalador localizado."

# Garante que a pasta de destino existe
if (-not (Test-Path $DestinoAbsoluto)) {
    New-Item -ItemType Directory -Force -Path $DestinoAbsoluto | Out-Null
    Write-Success "Pasta de destino criada: $DestinoAbsoluto"
} else {
    Write-Success "Pasta de destino verificada: $DestinoAbsoluto"
}

# -------------------------------------------------------------------------------
Write-Header "ETAPA 2 - Finalizando Processos Ativos"
try {
    $processos = Get-Process -Name "SintelAulaInstaller" -ErrorAction SilentlyContinue
    if ($processos) {
        Write-Warning "Finalizando instâncias em execução do SintelAulaInstaller.exe..."
        $processos | Stop-Process -Force
        Start-Sleep -Seconds 1.5
        Write-Success "Processos antigos finalizados."
    } else {
        Write-Success "Nenhum processo antigo em execução."
    }
} catch {
    Write-Warning "Aviso ao encerrar processos: $_"
}

# -------------------------------------------------------------------------------
Write-Header "ETAPA 3 - Compilação Otimizada (dotnet publish)"
Write-Step "Modo: Self-Contained, Single-File, Trimmed, Compressed"
Write-Step "Aguarde - a compilação com remoção de código morto pode demorar um pouco."

# Execução do dotnet publish com parâmetros otimizados de trimming
$dotnetCmd = "dotnet publish `"$ProjInstalador`" -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -p:PublishTrimmed=true -p:PublishReadyToRun=true -p:EnableCompressionInSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -p:SuppressTrimAnalysisWarnings=true -o `"$PastaSaida`""

Write-Step "Executando: $dotnetCmd"
Invoke-Expression $dotnetCmd

if ($LASTEXITCODE -ne 0) {
    Write-Failure "Erro na compilação do projeto."
    exit 1
}
Write-Success "Compilação concluída com sucesso."

# -------------------------------------------------------------------------------
Write-Header "ETAPA 4 - Cópia e Atualização do Executável de Teste"

$exeOrigem = Join-Path $PastaSaida $NomeExeFinal

if (-not (Test-Path $exeOrigem)) {
    Write-Failure "Executável de origem não encontrado em: $exeOrigem"
    exit 1
}

# Realiza a substituição forçada do executável na pasta de testes
Copy-Item -Path $exeOrigem -Destination $CaminhoExeFinal -Force
Write-Success "Instalador atualizado no ambiente de testes: $CaminhoExeFinal"

# Exibe o tamanho do executável otimizado (trimmed)
$tamanhoBytes = (Get-Item $CaminhoExeFinal).Length
$tamanhoMb    = [math]::Round($tamanhoBytes / 1MB, 2)
Write-Success "Tamanho do executável pós-remoção de código morto (Trimmed): ${tamanhoMb} MB"

# -------------------------------------------------------------------------------
$timer.Stop()
Write-Header "PUBLICAÇÃO E INSTALAÇÃO CONCLUÍDAS COM SUCESSO!"
Write-Host "  -> Tempo total de processamento: $($timer.Elapsed.TotalSeconds.ToString('F1')) segundos" -ForegroundColor Green
Write-Host "  -> Executável atualizado pronto para testes em: $CaminhoExeFinal`n" -ForegroundColor Cyan
