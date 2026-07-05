#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ============================================================================
# build_msix_store.ps1
# Geracao de pacote MSIX do SintelAula para envio a Microsoft Store
# Libera EdTech | v1.2.0.0
# ============================================================================
# Identidade do pacote (Partner Center):
#   Package Name : LberaEdTech.SintelAulaOficial
#   Publisher CN : CN=BA3135D3-F0A9-44A4-98BC-E5E74AC284C8
#   Store ID     : 9NZ3BKMGJK4L
#   PFN          : LberaEdTech.SintelAulaOficial_a638f8ybvnxx4
# ============================================================================

# -- Identidade e versao
$Version          = "1.2.0.0"
$PackageName      = "LberaEdTech.SintelAulaOficial"
$Publisher        = "CN=BA3135D3-F0A9-44A4-98BC-E5E74AC284C8"
$PublisherDisplay = "Libera EdTech"
$AppDisplayName   = "SintelAula"
$AppDescription   = "Sistema inteligente de gestao escolar para professores"
$AppBgColor       = "#1B3A6B"
$AppEntryPoint    = "SintelAulaInstaller.exe"

# -- Caminhos
$ScriptDir      = $PSScriptRoot
$PublishDir     = Join-Path $ScriptDir "src\SintelAula.Installer\bin\Release\net10.0-windows10.0.19041.0\win-x64\publish"
$MsixOutputDir  = "C:\Programa_SintelAula\Programa\Programa_Completo\SintelAula\Testar .exe\msix"
$MsixFileName   = "SintelAula_Oficial_${Version}_x64.msix"
$MsixOutputPath = Join-Path $MsixOutputDir $MsixFileName
$StagingDir     = Join-Path $MsixOutputDir "staging"

# -- Localiza makeappx.exe (versao mais recente no cache NuGet)
$NuGetBuildTools = Join-Path $env:USERPROFILE ".nuget\packages\microsoft.windows.sdk.buildtools"
$MakeAppxPath = $null
$Candidates = Get-ChildItem -Path $NuGetBuildTools -Filter "makeappx.exe" -Recurse -ErrorAction SilentlyContinue
$Best = ""
foreach ($c in $Candidates) {
    if ($c.FullName -like "*\x64\makeappx.exe") {
        if ($c.FullName -gt $Best) {
            $Best = $c.FullName
            $MakeAppxPath = $c.FullName
        }
    }
}

if (-not $MakeAppxPath) {
    Write-Host "[ERRO] makeappx.exe nao encontrado em: $NuGetBuildTools" -ForegroundColor Red
    exit 1
}

function Write-Ok   { param($t) Write-Host "  [OK] $t" -ForegroundColor Green }
function Write-Step { param($t) Write-Host "   -> $t"  -ForegroundColor White }
function Write-Warn { param($t) Write-Host "  [!]  $t" -ForegroundColor Yellow }
function Write-Fail { param($t) Write-Host "  [ERRO] $t" -ForegroundColor Red }
function Write-Header { param($t) Write-Host "`n=== $t ===" -ForegroundColor Cyan }

$timer = [System.Diagnostics.Stopwatch]::StartNew()

Write-Host ""
Write-Host "================================================================" -ForegroundColor Blue
Write-Host "   SintelAula - Geracao de MSIX (Microsoft Store)               " -ForegroundColor Blue
Write-Host "   $PackageName  |  v$Version                                   " -ForegroundColor Blue
Write-Host "================================================================" -ForegroundColor Blue

# -- ETAPA 1: Validacao
Write-Header "ETAPA 1 - Validacao"
if (-not (Test-Path $PublishDir)) {
    Write-Fail "Pasta publish nao encontrada: $PublishDir"
    Write-Fail "Execute build.ps1 primeiro!"
    exit 1
}
$ExeSource = Join-Path $PublishDir $AppEntryPoint
if (-not (Test-Path $ExeSource)) {
    Write-Fail "Executavel nao encontrado: $ExeSource"
    Write-Fail "Execute build.ps1 primeiro!"
    exit 1
}
Write-Ok "Executavel: $ExeSource"
Write-Ok "makeappx  : $MakeAppxPath"

# -- ETAPA 2: Prepara staging
Write-Header "ETAPA 2 - Preparando Staging"
if (Test-Path $StagingDir) {
    Remove-Item -Path $StagingDir -Recurse -Force
    Write-Step "Staging anterior limpo."
}
New-Item -Path $StagingDir       -ItemType Directory -Force | Out-Null
New-Item -Path $MsixOutputDir    -ItemType Directory -Force | Out-Null
$AssetsDir = Join-Path $StagingDir "Assets"
New-Item -Path $AssetsDir        -ItemType Directory -Force | Out-Null
Write-Ok "Staging criado em: $StagingDir"

# -- ETAPA 3: Copia o executavel
Write-Header "ETAPA 3 - Copiando Executavel"
Copy-Item -Path $ExeSource -Destination (Join-Path $StagingDir $AppEntryPoint) -Force
Write-Ok "Executavel copiado."

# Tenta copiar assets existentes
$SourceAssets = Join-Path $PublishDir "Assets"
if (-not (Test-Path $SourceAssets)) {
    $SourceAssets = Join-Path $ScriptDir "src\SintelAula.Installer\Assets"
}
if (Test-Path $SourceAssets) {
    Get-ChildItem -Path $SourceAssets | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $AssetsDir -Force
    }
    Write-Ok "Assets copiados de: $SourceAssets"
}

# -- ETAPA 4: Gera assets PNG obrigatorios
Write-Header "ETAPA 4 - Gerando Assets Visuais (PNG)"
Add-Type -AssemblyName System.Drawing

function New-Asset {
    param([int]$W, [int]$H, [string]$FileName)
    $path = Join-Path $AssetsDir $FileName
    if (Test-Path $path) {
        Write-Step "Asset existente mantido: $FileName"
        return
    }
    $bmp  = [System.Drawing.Bitmap]::new($W, $H)
    $g    = [System.Drawing.Graphics]::FromImage($bmp)
    $rect = [System.Drawing.Rectangle]::new(0, 0, $W, $H)
    $b1   = [System.Drawing.Color]::FromArgb(27, 58, 107)
    $b2   = [System.Drawing.Color]::FromArgb(0, 120, 212)
    $mode = [System.Drawing.Drawing2D.LinearGradientMode]::ForwardDiagonal
    $gb   = [System.Drawing.Drawing2D.LinearGradientBrush]::new($rect, $b1, $b2, $mode)
    $g.FillRectangle($gb, $rect)

    $minDim   = [Math]::Min($W, $H)
    $fontSize = [float][Math]::Max(8, ($minDim / 2.5))
    $font     = [System.Drawing.Font]::new("Segoe UI", $fontSize, [System.Drawing.FontStyle]::Bold)
    $wBrush   = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
    $text     = "SA"
    $ts       = $g.MeasureString($text, $font)
    $g.DrawString($text, $font, $wBrush, (($W - $ts.Width) / 2), (($H - $ts.Height) / 2))

    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    Write-Ok "Gerado: $FileName (${W}x${H})"
}

New-Asset 150 150 "Square150x150Logo.png"
New-Asset  44  44 "Square44x44Logo.png"
New-Asset  50  50 "StoreLogo.png"
New-Asset 310 150 "Wide310x150Logo.png"
New-Asset  71  71 "Square71x71Logo.png"
New-Asset 310 310 "Square310x310Logo.png"
New-Asset  44  44 "BadgeLogo.png"
New-Asset 620 300 "SplashScreen.png"

# -- ETAPA 5: Gera AppxManifest.xml
Write-Header "ETAPA 5 - Gerando AppxManifest.xml"
$ManifestPath = Join-Path $StagingDir "AppxManifest.xml"

$Manifest = '<?xml version="1.0" encoding="utf-8"?>' + "`r`n"
$Manifest += '<Package xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10"' + "`r`n"
$Manifest += '         xmlns:uap="http://schemas.microsoft.com/appx/manifest/uap/windows10"' + "`r`n"
$Manifest += '         xmlns:rescap="http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities"' + "`r`n"
$Manifest += '         IgnorableNamespaces="uap rescap">' + "`r`n"
$Manifest += "`r`n"
$Manifest += "  <Identity`r`n"
$Manifest += "    Name=`"$PackageName`"`r`n"
$Manifest += "    Publisher=`"$Publisher`"`r`n"
$Manifest += "    Version=`"$Version`"`r`n"
$Manifest += '    ProcessorArchitecture="x64" />' + "`r`n"
$Manifest += "`r`n"
$Manifest += "  <Properties>`r`n"
$Manifest += "    <DisplayName>$AppDisplayName</DisplayName>`r`n"
$Manifest += "    <PublisherDisplayName>$PublisherDisplay</PublisherDisplayName>`r`n"
$Manifest += "    <Logo>Assets\StoreLogo.png</Logo>`r`n"
$Manifest += "  </Properties>`r`n"
$Manifest += "`r`n"
$Manifest += "  <Dependencies>`r`n"
$Manifest += '    <TargetDeviceFamily Name="Windows.Desktop" MinVersion="10.0.17763.0" MaxVersionTested="10.0.26100.0" />' + "`r`n"
$Manifest += "  </Dependencies>`r`n"
$Manifest += "`r`n"
$Manifest += "  <Resources>`r`n"
$Manifest += '    <Resource Language="pt-BR" />' + "`r`n"
$Manifest += "  </Resources>`r`n"
$Manifest += "`r`n"
$Manifest += "  <Applications>`r`n"
$Manifest += "    <Application`r`n"
$Manifest += "      Id=`"App`"`r`n"
$Manifest += "      Executable=`"$AppEntryPoint`"`r`n"
$Manifest += '      EntryPoint="Windows.FullTrustApplication">' + "`r`n"
$Manifest += "      <uap:VisualElements`r`n"
$Manifest += "        DisplayName=`"$AppDisplayName`"`r`n"
$Manifest += "        Description=`"$AppDescription`"`r`n"
$Manifest += "        BackgroundColor=`"$AppBgColor`"`r`n"
$Manifest += '        Square150x150Logo="Assets\Square150x150Logo.png"' + "`r`n"
$Manifest += '        Square44x44Logo="Assets\Square44x44Logo.png">' + "`r`n"
$Manifest += "        <uap:DefaultTile`r`n"
$Manifest += '          Wide310x150Logo="Assets\Wide310x150Logo.png"' + "`r`n"
$Manifest += '          Square71x71Logo="Assets\Square71x71Logo.png"' + "`r`n"
$Manifest += '          Square310x310Logo="Assets\Square310x310Logo.png">' + "`r`n"
$Manifest += "          <uap:ShowNameOnTiles>`r`n"
$Manifest += '            <uap:ShowOn Tile="square150x150Logo" />' + "`r`n"
$Manifest += '            <uap:ShowOn Tile="wide310x150Logo" />' + "`r`n"
$Manifest += '            <uap:ShowOn Tile="square310x310Logo" />' + "`r`n"
$Manifest += "          </uap:ShowNameOnTiles>`r`n"
$Manifest += "        </uap:DefaultTile>`r`n"
$Manifest += '        <uap:SplashScreen Image="Assets\SplashScreen.png" />' + "`r`n"
$Manifest += "      </uap:VisualElements>`r`n"
$Manifest += "    </Application>`r`n"
$Manifest += "  </Applications>`r`n"
$Manifest += "`r`n"
$Manifest += "  <Capabilities>`r`n"
$Manifest += '    <rescap:Capability Name="runFullTrust" />' + "`r`n"
$Manifest += "  </Capabilities>`r`n"
$Manifest += "`r`n"
$Manifest += "</Package>`r`n"

[System.IO.File]::WriteAllText($ManifestPath, $Manifest, [System.Text.Encoding]::UTF8)
Write-Ok "AppxManifest.xml gerado."

# Valida estrutura XML
try {
    $xml = [xml](Get-Content $ManifestPath -Raw -Encoding UTF8)
    $id = $xml.Package.Identity
    Write-Ok "Manifesto valido: Name=$($id.Name) | Version=$($id.Version)"
} catch {
    Write-Warn "Aviso ao validar manifesto: $_"
}

# -- ETAPA 6: Empacotamento
Write-Header "ETAPA 6 - Empacotando com makeappx.exe"
Write-Step "makeappx: $MakeAppxPath"
Write-Step "Staging : $StagingDir"
Write-Step "Saida   : $MsixOutputPath"

if (Test-Path $MsixOutputPath) {
    Remove-Item -Path $MsixOutputPath -Force
    Write-Step "MSIX anterior removido."
}

& $MakeAppxPath pack /d $StagingDir /p $MsixOutputPath /o
if ($LASTEXITCODE -ne 0) {
    Write-Fail "makeappx.exe falhou com codigo $LASTEXITCODE"
    exit 1
}

# -- RELATORIO FINAL
$timer.Stop()
if (Test-Path $MsixOutputPath) {
    $sizeMB = [Math]::Round((Get-Item $MsixOutputPath).Length / 1MB, 2)
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "   MSIX GERADO COM SUCESSO!                                     " -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "  Arquivo  : $MsixFileName"          -ForegroundColor White
    Write-Host "  Local    : $MsixOutputDir"          -ForegroundColor White
    Write-Host "  Tamanho  : $sizeMB MB"              -ForegroundColor White
    Write-Host "  Versao   : $Version"                -ForegroundColor White
    Write-Host "  Pacote   : $PackageName"            -ForegroundColor White
    Write-Host "  Tempo    : $($timer.Elapsed.TotalSeconds.ToString('F1'))s" -ForegroundColor White
    Write-Host ""
    Write-Host "  PROXIMOS PASSOS PARA ENVIO:" -ForegroundColor Yellow
    Write-Host "  1. Acesse: https://partner.microsoft.com/dashboard" -ForegroundColor Gray
    Write-Host "  2. SintelAula -> Envios -> Criar novo envio" -ForegroundColor Gray
    Write-Host "  3. Secao Pacotes -> Carregar '$MsixFileName'" -ForegroundColor Gray
    Write-Host "  4. Nao e necessario assinar (Microsoft assina automaticamente)" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Fail "MSIX nao foi gerado. Verifique os logs acima."
    exit 1
}
