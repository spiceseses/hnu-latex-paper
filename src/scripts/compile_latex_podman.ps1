param(
    [string]$Image = "localhost/hnu-thesis-latex:tiny",
    [switch]$Clean,
    [switch]$NoCopy
)

$ErrorActionPreference = "Stop"

$srcRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$macroScript = Join-Path $PSScriptRoot "generate_chapter5_data_macros.ps1"
$buildDir = Join-Path $srcRoot "build"
$srcPath = $srcRoot.Path

function Convert-SyncTeXPath {
    param(
        [string]$Path,
        [string]$HostSourcePath
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    $hostPath = ($HostSourcePath -replace "\\", "/")
    if (-not $hostPath.EndsWith("/")) {
        $hostPath = "$hostPath/"
    }

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $inputStream = [System.IO.MemoryStream]::new($bytes)
    $gzipStream = [System.IO.Compression.GzipStream]::new($inputStream, [System.IO.Compression.CompressionMode]::Decompress)
    $reader = [System.IO.StreamReader]::new($gzipStream, [System.Text.Encoding]::UTF8)
    $content = $reader.ReadToEnd()
    $reader.Dispose()

    $content = $content.Replace("/work/./", $hostPath).Replace("/work/", $hostPath)

    $outputStream = [System.IO.MemoryStream]::new()
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    $gzipOutput = [System.IO.Compression.GzipStream]::new($outputStream, [System.IO.Compression.CompressionMode]::Compress)
    $writer = [System.IO.StreamWriter]::new($gzipOutput, $utf8NoBom)
    $writer.Write($content)
    $writer.Dispose()

    [System.IO.File]::WriteAllBytes($Path, $outputStream.ToArray())
}

if (-not $Clean) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $macroScript
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

$imageExists = $false
podman image exists $Image
if ($LASTEXITCODE -eq 0) {
    $imageExists = $true
}

if (-not $imageExists) {
    throw "Podman image '$Image' does not exist. Run .\src\scripts\build_latex_container.ps1 first."
}

$volume = "${srcPath}:/work"

if ($Clean) {
    podman run --rm -v $volume -w /work $Image latexmk -C -outdir=build main.tex
    exit $LASTEXITCODE
}

podman run --rm -v $volume -w /work $Image latexmk -xelatex -synctex=1 -interaction=nonstopmode -halt-on-error -file-line-error -outdir=build main.tex
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$pdfInBuild = Join-Path $buildDir "main.pdf"
$pdfAtRoot = Join-Path $srcRoot "main.pdf"
$synctexInBuild = Join-Path $buildDir "main.synctex.gz"
$synctexAtRoot = Join-Path $srcRoot "main.synctex.gz"

if ((Test-Path -LiteralPath $pdfInBuild) -and -not $NoCopy) {
    Copy-Item -LiteralPath $pdfInBuild -Destination $pdfAtRoot -Force
    Write-Host "PDF written to $pdfAtRoot"

    if (Test-Path -LiteralPath $synctexInBuild) {
        Convert-SyncTeXPath -Path $synctexInBuild -HostSourcePath $srcPath
        Copy-Item -LiteralPath $synctexInBuild -Destination $synctexAtRoot -Force
        Write-Host "SyncTeX written to $synctexAtRoot"
    }
}
