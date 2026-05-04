# ===========================================================================================
# KB SOLAR CRM - FIX APPCOLORS IMPORT PATHS
# Replace relative imports with correct package-style imports
# ===========================================================================================

param(
    [string]$RootPath = "D:\Flutter_Project\KB Solar CRM Frontend\lib",
    [switch]$DryRun = $false,
    [switch]$Verbose = $true
)

$script:TotalFilesProcessed = 0
$script:TotalReplacements = 0

function Get-AllDartFiles {
    param([string]$Path)
    Get-ChildItem -Path $Path -Filter "*.dart" -Recurse -File
}

function Fix-ImportPaths {
    param(
        [string]$FilePath
    )
    
    $content = Get-Content -Path $FilePath -Raw
    $originalContent = $content
    $replacementCount = 0
    
    # Skip if it's app_colors.dart itself
    if ($FilePath -match "app_colors\.dart$") {
        return 0
    }
    
    # Replace all incorrect relative import patterns with the correct package import
    $patterns = @(
        "import\s+'\.\.\/\.\.\/\.\.\/Helper\/app_colors\.dart';"           # Deep nested (5+ levels)
        "import\s+'\.\.\/\.\.\/\.\.\/\.\.\/Helper\/app_colors\.dart';"     # Very deep nested (6+ levels)
        "import\s+'\.\.\/\.\.\/\.\.\/\.\.\/\.\.\/Helper\/app_colors\.dart';" # Extremely deep (7+ levels)
        "import\s+'\.\.\/Helper\/app_colors\.dart';"                        # 2-3 levels
        "import\s+\.\.\/Helper\/app_colors\.dart';"                         # Malformed
    )
    
    $correctImport = "import 'package:solar_project/Helper/app_colors.dart';"
    
    foreach ($pattern in $patterns) {
        if ($content -match $pattern) {
            $content = $content -replace $pattern, $correctImport
            $replacementCount++
            break  # Only replace once per file
        }
    }
    
    # Ensure only one import of app_colors exists (remove duplicates)
    $lines = $content -split "`n"
    $appColorsImportCount = 0
    $cleanedLines = @()
    
    foreach ($line in $lines) {
        if ($line -match "import.*app_colors\.dart") {
            if ($appColorsImportCount -eq 0) {
                $cleanedLines += $line
                $appColorsImportCount++
            }
            # Skip duplicate imports
        } else {
            $cleanedLines += $line
        }
    }
    
    $newContent = $cleanedLines -join "`n"
    
    # Write if changes were made
    if ($newContent -ne $originalContent) {
        if (-not $DryRun) {
            Set-Content -Path $FilePath -Value $newContent -Force
        }
        
        $script:TotalReplacements += $replacementCount
        
        if ($Verbose) {
            $fileName = [System.IO.Path]::GetFileName($FilePath)
            if ($replacementCount -gt 0) {
                Write-Host "FIXED: $fileName - updated import path"
            }
        }
        
        return $replacementCount
    }
    
    return 0
}

function Main {
    Write-Host "============================================================================================="
    Write-Host "KB SOLAR CRM - FIX APPCOLORS IMPORT PATHS"
    Write-Host "============================================================================================="
    Write-Host ""
    
    if ($DryRun) {
        Write-Host "WARNING: DRY RUN MODE - No files will be modified"
        Write-Host ""
    }
    
    Write-Host "Processing Dart files in: $RootPath"
    Write-Host ""
    
    # Get all dart files
    $dartFiles = Get-AllDartFiles -Path $RootPath
    Write-Host "Found $($dartFiles.Count) Dart files"
    Write-Host ""
    
    # Process each file
    foreach ($file in $dartFiles) {
        $replacementCount = Fix-ImportPaths -FilePath $file.FullName
        
        if ($replacementCount -gt 0) {
            $script:TotalFilesProcessed++
        }
    }
    
    # Summary Report
    Write-Host ""
    Write-Host "============================================================================================="
    Write-Host "IMPORT PATH FIX SUMMARY"
    Write-Host "============================================================================================="
    Write-Host ""
    Write-Host "Total Files Fixed: $($script:TotalFilesProcessed)"
    Write-Host "Total Import Fixes: $($script:TotalReplacements)"
    Write-Host ""
    Write-Host "Status: $(if ($DryRun) { 'DRY RUN - NO CHANGES MADE' } else { 'COMPLETED' })"
    Write-Host "============================================================================================="
}

# Run main function
Main
