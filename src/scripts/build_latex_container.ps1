param(
    [string]$Image = "localhost/hnu-thesis-latex:tiny"
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$contextDir = Join-Path $repoRoot "container\latex"
$containerfile = Join-Path $contextDir "Containerfile"

podman build --pull=missing -t $Image -f $containerfile $contextDir
