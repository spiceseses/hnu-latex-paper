param(
    [string]$CsvPath = "data/chapter5_experiment_data.csv",
    [string]$TexPath = "docs/generated/chapter5_experiment_data.tex"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$csvFullPath = Join-Path $root $CsvPath
$texFullPath = Join-Path $root $TexPath

$rows = Import-Csv -LiteralPath $csvFullPath

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("% Auto-generated from data/chapter5_experiment_data.csv.")
$lines.Add("% Re-run scripts/generate_chapter5_data_macros.ps1 after editing the CSV.")
$lines.Add("\providecommand{\ChFiveData}[1]{%")
$lines.Add("\ifcsname ChFiveData@\detokenize{#1}\endcsname%")
$lines.Add("\csname ChFiveData@\detokenize{#1}\endcsname%")
$lines.Add("\else%")
$lines.Add("\textbf{??}%")
$lines.Add("\fi%")
$lines.Add("}")

foreach ($row in $rows) {
    if ([string]::IsNullOrWhiteSpace($row.key)) {
        continue
    }

    $key = $row.key.Trim()
    $value = $row.value
    $lines.Add("\expandafter\gdef\csname ChFiveData@\detokenize{$key}\endcsname{$value}")
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllLines($texFullPath, $lines, $utf8NoBom)
