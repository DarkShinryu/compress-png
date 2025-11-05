# compress_png.ps1
# Usage examples:
#   pwsh Compress-PNGs.ps1 "C:\Textures"              # default compression (opt=2)
#   pwsh Compress-PNGs.ps1 "C:\Textures" -m           # max compression
#   pwsh Compress-PNGs.ps1 "C:\Textures" -z           # zopfli compression (slow)
#   pwsh Compress-PNGs.ps1 "C:\Textures" -m -z        # max + zopfli (very slow)
#   pwsh Compress-PNGs.ps1 "C:\Textures" -c           # auto CSV with timestamp
#   pwsh Compress-PNGs.ps1 "C:\Textures" -c -p "C:\log.csv" # custom CSV path

param(
    [string]$InputFolder = ".",
    [int]$MaxCores = [Environment]::ProcessorCount,

    [Alias("s")]
    [switch]$SkipExisting,

    [Alias("m")]
    [switch]$Max,

    [Alias("z")]
    [switch]$Zopfli,

    [Alias("c")]
    [switch]$CsvLog,

    [Alias("p")]
    [string]$CsvPath
)

$InputFolder = (Resolve-Path $InputFolder).Path
$oxipng = "oxipng.exe"

if (-not (Get-Command $oxipng -ErrorAction SilentlyContinue)) {
    Write-Error "oxipng.exe not found. Place it in the same folder as this script or add it to PATH."
    exit 1
}

$outputFolder = Join-Path $InputFolder "compressed"
New-Item -ItemType Directory -Force -Path $outputFolder | Out-Null

# Compression settings
$args = @("--strip", "all")
if ($Max) {
    $args += "--opt=max"
    Write-Host "Running in MAX mode."
} else {
    $args += "--opt=2"
    Write-Host "Running in DEFAULT mode (opt=2)."
}
if ($Zopfli) {
    $args += "--zopfli"
    Write-Host "Zopfli enabled (much slower)."
}

# Gather PNGs but exclude the output folder
$files = Get-ChildItem -Path $InputFolder -Filter *.png -Recurse |
         Where-Object { $_.FullName -notlike "$outputFolder*" }

$total = $files.Count
if ($total -eq 0) { Write-Host "No PNG files found."; exit }

Write-Host "About to process $total PNG files in: $InputFolder"
Write-Host "Output will be saved under: $outputFolder"

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Collect results instead of printing live
$results = $files | ForEach-Object -Parallel {
    $relativePath = $_.FullName.Substring($using:InputFolder.Length).TrimStart('\','/')
    $outputFile   = Join-Path $using:outputFolder $relativePath
    $outputDir    = Split-Path $outputFile
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

    if ($using:SkipExisting -and (Test-Path $outputFile)) {
        return [PSCustomObject]@{
            File   = $relativePath
            Status = "Skipped"
            Before = (Get-Item $_.FullName).Length
            After  = (Get-Item $outputFile).Length
        }
    }

    $before = (Get-Item $_.FullName).Length
    & $using:oxipng @using:args $_.FullName --out $outputFile
    $exit = $LASTEXITCODE

    if ($exit -eq 0 -and (Test-Path $outputFile)) {
        $after = (Get-Item $outputFile).Length
        return [PSCustomObject]@{
            File   = $relativePath
            Status = "Compressed"
            Before = $before
            After  = $after
        }
    } else {
        return [PSCustomObject]@{
            File   = $relativePath
            Status = "Failed"
            Before = $before
            After  = $null
        }
    }
} -ThrottleLimit $MaxCores

$stopwatch.Stop()

# Print results in order
Write-Host ""
Write-Host "=== Detailed Results ==="
Write-Host ("{0,-40} {1,12} {2,12} {3,12}" -f "File", "Before (KB)", "After (KB)", "Saved %")
Write-Host ("{0,-40} {1,12} {2,12} {3,12}" -f ("-"*40), ("-"*12), ("-"*12), ("-"*12))

$results | Sort-Object File | ForEach-Object {
    if ($_.Status -eq "Compressed") {
        $saved = $_.Before - $_.After
        $pct   = if ($_.Before -gt 0) { "{0:P2}" -f ($saved / $_.Before) } else { "n/a" }
        $beforeKB = "{0:N1}" -f ($_.Before / 1KB)
        $afterKB  = "{0:N1}" -f ($_.After / 1KB)
        Write-Host ("{0,-40} {1,12} {2,12} {3,12}" -f $_.File, $beforeKB, $afterKB, $pct) -ForegroundColor Green
    } elseif ($_.Status -eq "Skipped") {
        Write-Host ("{0,-40} {1,12} {2,12} {3,12}" -f $_.File, "[Skipped]", "-", "-") -ForegroundColor Yellow
    } else {
        Write-Host ("{0,-40} {1,12} {2,12} {3,12}" -f $_.File, "[Failed]", "-", "-") -ForegroundColor Red
    }
}

# Summary
$successes = ($results | Where-Object Status -eq "Compressed").Count
$failures  = ($results | Where-Object Status -eq "Failed").Count
$skipped   = ($results | Where-Object Status -eq "Skipped").Count

$totalBefore = ($results | Where-Object Status -eq "Compressed" | Measure-Object Before -Sum).Sum
$totalAfter  = ($results | Where-Object Status -eq "Compressed" | Measure-Object After -Sum).Sum
$totalSaved  = $totalBefore - $totalAfter
$pctTotal    = if ($totalBefore -gt 0) { "{0:P2}" -f ($totalSaved / $totalBefore) } else { "n/a" }

Write-Host ""
Write-Host "=== Summary Report ==="
Write-Host "Total files:    $total"
Write-Host "Succeeded:      $successes"
Write-Host "Failed:         $failures"
Write-Host "Skipped:        $skipped"
Write-Host ("Total before:   {0:N1} KB" -f ($totalBefore / 1KB))
Write-Host ("Total after:    {0:N1} KB" -f ($totalAfter / 1KB))
Write-Host ("Total saved:    {0:N1} KB ({1} smaller)" -f ($totalSaved / 1KB), $pctTotal)
Write-Host ("Elapsed time:   {0:hh\:mm\:ss}" -f $stopwatch.Elapsed)
Write-Host "Output folder:  $outputFolder"

# Optional CSV export
if ($CsvLog) {
    if (-not $CsvPath) {
        $timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
        $CsvPath = Join-Path $InputFolder ("results-{0}.csv" -f $timestamp)
    }

    $results | Sort-Object File | Select-Object File, Status,
        @{Name="BeforeKB";Expression={"{0:N1}" -f ($_.Before / 1KB)}},
        @{Name="AfterKB";Expression={if ($_.After) {"{0:N1}" -f ($_.After / 1KB)} else {"-"}}},
        @{Name="Saved%";Expression={if ($_.Status -eq "Compressed" -and $_.Before -gt 0) { "{0:P2}" -f (($_.Before - $_.After) / $_.Before) } else {"-"}}} |
        Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8

    Write-Host "Detailed results exported to: $CsvPath"
}
