# ===========================================================================================
# KB SOLAR CRM - ADD MISSING APPCOLORS IMPORTS (PHASE 5)
# Add 'import' statement to files that reference AppColors but don't import it
# ===========================================================================================

param(
    [string]$RootPath = "D:\Flutter_Project\KB Solar CRM Frontend\lib",
    [switch]$DryRun = $false,
    [switch]$Verbose = $true
)

$script:TotalFilesProcessed = 0
$script:ImportsAdded = 0
$script:FileChanges = @()

function Get-AllDartFiles {
    param([string]$Path)
    Get-ChildItem -Path $Path -Filter "*.dart" -Recurse -File
}

function Add-AppColorsImport {
    param(
        [string]$FilePath
    )
    
    $content = Get-Content -Path $FilePath -Raw
    
    # Check if file uses AppColors
    if ($content -notmatch "AppColors\.") {
        return $false
    }
    
    # Check if file already imports AppColors
    if ($content -match "import.*app_colors|from.*app_colors") {
        return $false
    }
    
    # Check if it's the app_colors.dart file itself
    if ($FilePath -match "app_colors\.dart$") {
        return $false
    }
    
    # Find the import section (after package and material imports)
    $lines = $content -split "`n"
    $insertIndex = -1
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        
        # Find the last import statement
        if ($line -match "^import\s") {
            $insertIndex = $i
        }
        # Stop if we hit a non-import line (like a blank line or comment after imports)
        elseif ($insertIndex -gt -1 -and $line -notmatch "^import|^$|^//") {
            break
        }
    }
    
    # If we found where to insert, add the import
    if ($insertIndex -gt -1) {
        $importStatement = "import '../../../Helper/app_colors.dart';"
        
        # Adjust import path based on file depth
        if ($FilePath -match "screens[/\\]Dashboards") {
            $importStatement = "import '../../../../../Helper/app_colors.dart';"
        }
        elseif ($FilePath -match "screens") {
            $importStatement = "import '../../../../Helper/app_colors.dart';"
        }
        
        $lines[$insertIndex] += "`n$importStatement"
        $newContent = $lines -join "`n"
        
        if (-not $DryRun) {
            Set-Content -Path $FilePath -Value $newContent -Force
        }
        
        $script:ImportsAdded++
        $script:FileChanges += @{
            File = $FilePath
            Import = $importStatement
        }
        
        if ($Verbose) {
            Write-Host "Added import to: $([System.IO.Path]::GetFileName($FilePath))"
        }
        
        return $true
    }
    
    return $false
}

function Main {
    Write-Host "============================================================================================="
    Write-Host "KB SOLAR CRM - ADD MISSING APPCOLORS IMPORTS (PHASE 5)"
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
        if (Add-AppColorsImport -FilePath $file.FullName) {
            $script:TotalFilesProcessed++
        }
    }
    
    # Summary Report
    Write-Host ""
    Write-Host "============================================================================================="
    Write-Host "PHASE 5 - ADD IMPORTS SUMMARY"
    Write-Host "============================================================================================="
    Write-Host ""
    Write-Host "Total Files Processed: $($script:TotalFilesProcessed)"
    Write-Host "Total Imports Added: $($script:ImportsAdded)"
    Write-Host ""
    
    if ($script:FileChanges.Count -gt 0) {
        Write-Host "Modified Files:"
        $script:FileChanges | ForEach-Object {
            Write-Host "  - $($_.File)"
        }
    }
    
    Write-Host ""
    Write-Host "Status: $(if ($DryRun) { 'DRY RUN - NO CHANGES MADE' } else { 'COMPLETED' })"
    Write-Host "============================================================================================="
}

# Run main function
Main
