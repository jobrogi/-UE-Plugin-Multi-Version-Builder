<#
MIT License

Copyright (c) 2025 Ghillie Studios

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

# -------------------------------
# UE Plugin Multi-Version Builder
# -------------------------------

# Steps to use this script:
# 1. After Developing Plugin Place Plugin folder in the desktop folder.
#    This minimizes the path character length. Too many characters and the build will fail.
# 2. Edit this script’s pluginRoot + outputRoot + outputName variables.
# 3. Ensure $versions match your installed Unreal Engine paths.

# Set plugin root path here
$pluginRoot = "C:\Users\jobro\Desktop\FastNoiseLiteFunctionLibrary"

# Set Output Folder Path (IE: Desktop File Path)
$outputRoot = "C:\Users\jobro\Desktop"

# Set versioned output folder base name (e.g., "Example" -> "Example_5.3")
$outputName = "FNSFuncLib"

# Validate required input values
if ([string]::IsNullOrWhiteSpace($pluginRoot) -or
    [string]::IsNullOrWhiteSpace($outputRoot) -or
    [string]::IsNullOrWhiteSpace($outputName)) {
    Write-Error " Please fill in pluginRoot, outputRoot, and outputName before running this script."
    Read-Host "Press Enter to exit"
    exit 1
}

if (!(Test-Path $pluginRoot)) {
    Write-Error " Plugin path does not exist: $pluginRoot"
    Read-Host "Press Enter to exit"
    exit 1
}

# Supported UE versions and install paths
$versions = @{
    "5.3" = "C:\Program Files\Epic Games\UE_5.3"
    "5.4" = "C:\Program Files\Epic Games\UE_5.4"
    "5.5" = "C:\Program Files\Epic Games\UE_5.5"
    "5.6" = "C:\Program Files\Epic Games\UE_5.6"
}

# Find .uplugin file
$uplugin = Get-ChildItem -Path $pluginRoot -Filter *.uplugin | Select-Object -First 1
if (!$uplugin) {
    Write-Error "No .uplugin file found in: $pluginRoot"
    Read-Host "Press Enter to exit"
    exit 1
}

$pluginPath = $uplugin.FullName
$pluginName = $uplugin.BaseName
$baseOutput = Join-Path $outputRoot $outputName

# Create output directory if it doesn't exist
if (!(Test-Path $baseOutput)) {
    New-Item -ItemType Directory -Path $baseOutput | Out-Null
}

# Timestamp for log filenames
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Track build status
$buildFailed = $false

foreach ($version in $versions.Keys) {
    $enginePath = $versions[$version]
    $uatPath = Join-Path $enginePath "Engine\Build\BatchFiles\RunUAT.bat"

    $versionFolderName = "${outputName}_$version"
    $outputPath = Join-Path $baseOutput $versionFolderName
    $logFile = "$baseOutput\BuildLog_${versionFolderName}_$timestamp.txt"

    Write-Host "`n Building $pluginName for UE $version..." -ForegroundColor Cyan
    Write-Host "-> UAT Path: $uatPath"
    Write-Host "-> Output Folder: $outputPath"
    Write-Host "-> Log File: $logFile"

    & $uatPath "BuildPlugin" `
        "-Plugin=$pluginPath" `
        "-Package=$outputPath" `
        "-Rocket" "-TargetPlatforms=Win64" `
        *>> "$logFile"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Build FAILED for UE $version. See log for details." -ForegroundColor Red
        $buildFailed = $true
    } else {
        Write-Host "Build SUCCEEDED for UE $version." -ForegroundColor Green
    }
}

# Final summary and pause
if ($buildFailed) {
    Write-Host "`n One or more builds failed." -ForegroundColor Yellow
} else {
    Write-Host "`n All builds succeeded!" -ForegroundColor Green
}

Read-Host "Press Enter to exit"
