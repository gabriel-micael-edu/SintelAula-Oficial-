# ===============================================================================
# build.ps1 - Script de Compilacao Automatizada do SintelAula PARTE 1
# Organizacao: Libera EdTech | .NET 10 | WinUI 3 | Windows App SDK 1.7
# -----------------------------------------------------------------------------
# O que este script faz:
#   1. Valida o ambiente (.NET SDK, PowerShell version)
#   2. Restaura todos os pacotes NuGet da solucao
#   3. Limpa builds anteriores
#   4. Compila e publica o SintelAula.Installer como Single-File Self-Contained
#   5. Renomeia o .exe para SintelAula(Desenvolvimento).exe
#   6. Copia o executavel final para a pasta de testes
#   7. Exibe relatorio de build com tamanho e tempo
#
# NOTA: O empacotamento MSIX NAO e realizado por este script.
#       Use a MSIX Packaging Tool da Microsoft para empacotar manualmente
#       o SintelAula.App apos a validacao desta etapa.
# ===============================================================================

#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -- Configuracao de cores para output formatado ------------------------------
function Write-Cabecalho($texto) { Write-Host "`n== $texto ==" -ForegroundColor Cyan }
function Write-Passo($texto)     { Write-Host "  -> $texto"    -ForegroundColor White }
function Write-Ok($texto)        { Write-Host "  [OK] $texto"    -ForegroundColor Green }
function Write-Aviso($texto)     { Write-Host "  [AVISO] $texto"   -ForegroundColor Yellow }
function Write-Erro($texto)      { Write-Host "  [ERRO] $texto"    -ForegroundColor Red }

# -- Caminhos absolutos --------------------------------------------------------
$RaizProjeto    = $PSScriptRoot   # Pasta onde este script esta (Codigo Fonte\)
$ProjInstalador = Join-Path $RaizProjeto "src\SintelAula.Installer\SintelAula.Installer.csproj"
$PastaDestino   = "C:\Programa_SintelAula\Programa\Programa_Completo\SintelAula\Testar .exe"
$NomeExeFinal   = "SintelAulaInstaller.exe"

# Nome interno do assembly gerado pelo dotnet publish (definido no .csproj)
$NomeAssembly   = "SintelAulaInstaller.exe"

# -- Timer de build ------------------------------------------------------------
$inicioTotal = [System.Diagnostics.Stopwatch]::StartNew()

# ================================================================================
Write-Host ""
Write-Host "================================================================" -ForegroundColor Blue
Write-Host "         SintelAula - Build Automatizado (PARTE 1)              " -ForegroundColor Blue
Write-Host "               Libera EdTech  |  .NET 10  |  WinUI 3            " -ForegroundColor Blue
Write-Host "================================================================" -ForegroundColor Blue

# -- ETAPA 1: Validacao do ambiente -------------------------------------------
Write-Cabecalho "ETAPA 1 - Validando Ambiente"

# Verifica se o .NET SDK esta instalado e e a versao correta
try {
    $sdkVersion = (dotnet --version 2>&1).Trim()
    Write-Ok ".NET SDK encontrado: $sdkVersion"
} catch {
    Write-Erro ".NET SDK nao encontrado. Instale o .NET 10 SDK e tente novamente."
    exit 1
}

# Verifica se o SDK 10.x esta disponivel
$sdks = dotnet --list-sdks 2>&1
$sdk10 = $sdks | Where-Object { $_ -match "^10\." }
if (-not $sdk10) {
    Write-Erro ".NET 10 SDK nao encontrado. SDKs disponiveis:`n$sdks"
    Write-Aviso "Baixe o .NET 10 SDK em: https://dot.net/download/10.0"
    exit 1
}
Write-Ok ".NET 10 SDK disponivel: $($sdk10 | Select-Object -First 1)"

# Verifica se o projeto do instalador existe
if (-not (Test-Path $ProjInstalador)) {
    Write-Erro "Projeto nao encontrado: $ProjInstalador"
    exit 1
}
Write-Ok "Projeto do instalador localizado."

# Garante que a pasta de destino existe
if (-not (Test-Path $PastaDestino)) {
    New-Item -ItemType Directory -Force -Path $PastaDestino | Out-Null
    Write-Ok "Pasta de destino criada: $PastaDestino"
} else {
    Write-Ok "Pasta de destino verificada: $PastaDestino"
}

# -- ETAPA 2: Restauracao de pacotes NuGet ------------------------------------
Write-Cabecalho "ETAPA 2 - Restaurando Pacotes NuGet"
Write-Passo "Restaurando dependencias do SintelAula.Installer..."

$inicio = [System.Diagnostics.Stopwatch]::StartNew()

$saida = dotnet restore $ProjInstalador `
    --runtime win-x64 `
    /p:Configuration=Release `
    2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Erro "Falha na restauracao dos pacotes:`n$saida"
    exit 1
}

$inicio.Stop()
Write-Ok "Pacotes restaurados em $($inicio.Elapsed.TotalSeconds.ToString('F1'))s"

# -- ETAPA 3: Limpeza do build anterior ---------------------------------------
Write-Cabecalho "ETAPA 3 - Limpando Build Anterior"
Write-Passo "Executando dotnet clean..."

$saida = dotnet clean $ProjInstalador `
    --configuration Release `
    --runtime win-x64 `
    2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Aviso "Clean retornou avisos (nao critico): $saida"
} else {
    Write-Ok "Diretorios de build anteriores removidos."
}

# -- ETAPA 4: Compilacao e Publicacao (Single-File + Self-Contained) ----------
Write-Cabecalho "ETAPA 4 - Compilando SintelAula.Installer (Release / win-x64)"
Write-Passo "dotnet publish com SingleFile + SelfContained + Trimmed..."
Write-Passo "Aguarde - este processo pode levar 1-3 minutos na primeira vez."

$pastaSaida = Join-Path $RaizProjeto "src\SintelAula.Installer\bin\Release\net10.0-windows10.0.19041.0\win-x64\publish"

$inicio = [System.Diagnostics.Stopwatch]::StartNew()

$saida = dotnet publish $ProjInstalador `
    --configuration Release `
    --runtime win-x64 `
    --self-contained true `
    -p:PublishSingleFile=true `
    -p:EnableCompressionInSingleFile=true `
    -p:PublishTrimmed=false `
    -p:PublishReadyToRun=true `
    -p:IncludeNativeLibrariesForSelfExtract=true `
    -p:SuppressTrimAnalysisWarnings=true `
    --output "$pastaSaida" `
    2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Erro "Falha na compilacao. Log completo:`n$saida"
    exit 1
}

$inicio.Stop()
Write-Ok "Compilacao concluida em $($inicio.Elapsed.TotalSeconds.ToString('F1'))s"

# -- ETAPA 5: Renomear e copiar para a pasta de testes ------------------------
Write-Cabecalho "ETAPA 5 - Gerando SintelAulaInstaller.exe"

$exeOrigem  = Join-Path $pastaSaida $NomeAssembly
$exeDestino = Join-Path $PastaDestino $NomeExeFinal

if (-not (Test-Path $exeOrigem)) {
    Write-Erro "Executavel nao encontrado apos build: $exeOrigem"
    Write-Passo "Conteudo da pasta de saida:"
    Get-ChildItem $pastaSaida -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "    $_" }
    exit 1
}

# Garante que o processo do instalador antigo nao esteja rodando
try {
    $processos = Get-Process -Name "SintelAulaInstaller" -ErrorAction SilentlyContinue
    if ($processos) {
        Write-Aviso "Finalizando processo existente SintelAulaInstaller.exe..."
        $processos | Stop-Process -Force
        Start-Sleep -Seconds 1
    }
} catch {
    Write-Aviso "Nao foi possivel parar o processo: $_"
}

# Copia com o nome final correto (renomeando)
Copy-Item -Path $exeOrigem -Destination $exeDestino -Force
Write-Ok "Executavel final gerado: $exeDestino"

# Copia a pasta Assets para que a logomarca e outros recursos locais fiquem disponiveis na pasta de testes
$assetsOrigem  = Join-Path $pastaSaida "Assets"
$assetsDestino = Join-Path $PastaDestino "Assets"
if (Test-Path $assetsOrigem) {
    Copy-Item -Path $assetsOrigem -Destination $assetsDestino -Recurse -Force
    Write-Ok "Pasta Assets copiada para pasta de testes."
}

# Tamanho do arquivo gerado
$tamanhoBytes = (Get-Item $exeDestino).Length
$tamanhoMb    = [math]::Round($tamanhoBytes / 1MB, 2)
Write-Ok "Tamanho do executavel: ${tamanhoMb} MB"

# -- RELATORIO FINAL ------------------------------------------------------------
$inicioTotal.Stop()

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "                    BUILD CONCLUIDO!                            " -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Arquivo gerado : $NomeExeFinal" -ForegroundColor White
Write-Host "  Localizacao    : $PastaDestino" -ForegroundColor White
Write-Host "  Tamanho        : ${tamanhoMb} MB" -ForegroundColor White
Write-Host "  Tempo total    : $($inicioTotal.Elapsed.TotalSeconds.ToString('F1'))s" -ForegroundColor White
Write-Host ""
Write-Host "  Para testar: de dois cliques em '$NomeExeFinal'" -ForegroundColor Cyan
Write-Host "     (O UAC solicitara elevacao - necessario para PackageManager)" -ForegroundColor Gray
Write-Host ""
Write-Host "  PROXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "     1. Valide a interface WinUI 3 do instalador" -ForegroundColor Gray
Write-Host "     2. Teste o botao 'Politica de Privacidade' (PDF gerado em tempo real)" -ForegroundColor Gray
Write-Host "     3. Prossiga para a Parte 2: core do SintelAula.App" -ForegroundColor Gray
Write-Host ""
