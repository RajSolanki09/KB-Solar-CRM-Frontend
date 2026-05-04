# ===========================================================================================
# KB SOLAR CRM - CLEANUP COLOR CONSTRUCTORS (PHASE 6)
# Remove Color() wrapper from AppColors constants
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

function Cleanup-ColorConstructors {
    param(
        [string]$FilePath
    )
    
    $content = Get-Content -Path $FilePath -Raw
    $originalContent = $content
    $replacementCount = 0
    
    # Remove Color() wrapper from AppColors constants
    # Matches: Color(AppColors.xxx) or const Color(AppColors.xxx)
    $pattern = "const\s+Color\(AppColors\."
    $replacement = "AppColors."
    
    $beforeCount = [regex]::Matches($content, [regex]::Escape($pattern)).Count + 
                   [regex]::Matches($content, [regex]::Escape("Color(AppColors.")).Count
    
    if ($beforeCount -gt 0) {
        # Remove "const Color(" prefix
        $content = $content -replace "const\s+Color\(AppColors\.", "AppColors."
        # Remove regular "Color(" prefix
        $content = $content -replace "Color\(AppColors\.", "AppColors."
        
        $replacementCount += $beforeCount
    }
    
    # Fix any remaining Color(0xFFxxxxxx) that weren't caught by previous script
    # These should be mapped to appropriate AppColors constants or left as-is if unmapped
    $unmappedColors = @(
        "0xFF6366F1" # Indigo - could be accent or info
    )
    
    foreach ($hexColor in $unmappedColors) {
        $colorPattern = "Color\($hexColor\)"
        if ($content -match $colorPattern) {
            # For unmapped colors, keep as Color(0xFFxxxxxx) since we don't have a semantic mapping
            # This is OK - it means these are edge cases not part of the design system
        }
    }
    
    # Write if changes were made
    if ($content -ne $originalContent) {
        if (-not $DryRun) {
            Set-Content -Path $FilePath -Value $content -Force
        }
        
        $script:TotalReplacements += $replacementCount
        
        if ($Verbose -and $replacementCount -gt 0) {
            Write-Host "CLEANED: $([System.IO.Path]::GetFileName($FilePath)) - $replacementCount removals"
        }
        
        return $replacementCount
    }
    
    return 0
}

function Main {
    Write-Host "============================================================================================="
    Write-Host "KB SOLAR CRM - CLEANUP COLOR CONSTRUCTORS (PHASE 6)"
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
        $replacementCount = Cleanup-ColorConstructors -FilePath $file.FullName
        
        if ($replacementCount -gt 0) {
            $script:TotalFilesProcessed++
        }
    }
    
    # Summary Report
    Write-Host ""
    Write-Host "============================================================================================="
    Write-Host "PHASE 6 EXECUTION SUMMARY"
    Write-Host "============================================================================================="
    Write-Host ""
    Write-Host "Total Files Modified: $($script:TotalFilesProcessed)"
    Write-Host "Total Replacements: $($script:TotalReplacements)"
    Write-Host ""
    Write-Host "Status: $(if ($DryRun) { 'DRY RUN - NO CHANGES MADE' } else { 'COMPLETED' })"
    Write-Host "============================================================================================="
}

# Run main function
Main
