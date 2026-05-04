# ===========================================================================================
# KB SOLAR CRM - COLOR MIGRATION AUTO-SCRIPT (PHASE 3 & 4)
# Bulk Find & Replace for Hardcoded Colors -> AppColors Constants
# ===========================================================================================

param(
    [string]$RootPath = "D:\Flutter_Project\KB Solar CRM Frontend\lib",
    [switch]$DryRun = $false,
    [switch]$Verbose = $true
)

# Color mapping table: Hardcoded Hex -> AppColors Constant
$ColorMappings = @{
    # TEXT COLORS
    "0xFF111827" = "AppColors.textPrimary"
    "0xFF374151" = "AppColors.textPrimary"
    "0xFF6B7280" = "AppColors.textSecondary"
    "0xFF9CA3AF" = "AppColors.textTertiary"
    "0xFFD1D5DB" = "AppColors.textLight"
    
    # BACKGROUND COLORS
    "0xFFF3E8FF" = "AppColors.bgPrimary"
    "0xFFFAF5FF" = "AppColors.bgSecondary"
    "0xFFF8FAFC" = "AppColors.bgSecondary"
    "0xFFF5F3FF" = "AppColors.primaryLightest"
    "0xFFF4F6FA" = "AppColors.bgSecondary"
    "0xFFF9FAFB" = "AppColors.bgSecondary"
    "0xFFE2E8F0" = "AppColors.bgPrimary"
    "0xFFF3F4FF" = "AppColors.primaryLightest"
    "0xFFE8EAFF" = "AppColors.primaryLightest"
    "0xFFF5F5F5" = "AppColors.bgDisabled"
    
    # BORDER COLORS
    "0xFFE5E7EB" = "AppColors.borderLight"
    "0xFFD4BFFF" = "AppColors.borderPrimary"
    
    # PRIMARY & BRAND COLORS
    "0xFF9F5BFF" = "AppColors.primary"
    "0xFFA855F7" = "AppColors.primaryLight"
    "0xFF7B2FF7" = "AppColors.accent2"
    
    # SUCCESS/ERROR/WARNING/INFO COLORS
    "0xFF43E97B" = "AppColors.success"
    "0xFF166534" = "AppColors.success"
    "0xFFDC2626" = "AppColors.error"
    "0xFFF59E0B" = "AppColors.warning"
    "0xFF3B82F6" = "AppColors.info"
    
    # ADDITIONAL VARIANTS
    "0xFFE6D5FF" = "AppColors.primaryLighter"
    "0xFFB08BFF" = "AppColors.primaryLight"
}

$script:TotalFilesProcessed = 0
$script:TotalReplacements = 0
$script:FileChanges = @()

function Get-AllDartFiles {
    param([string]$Path)
    Get-ChildItem -Path $Path -Filter "*.dart" -Recurse -File
}

function Replace-ColorInFile {
    param(
        [string]$FilePath,
        [hashtable]$Mappings
    )
    
    $content = Get-Content -Path $FilePath -Raw
    $originalContent = $content
    $fileReplacements = 0
    
    # Replace each color mapping
    foreach ($hexColor in $Mappings.Keys) {
        $appColor = $Mappings[$hexColor]
        
        # Count occurrences before replacement
        $beforeCount = [regex]::Matches($content, [regex]::Escape($hexColor)).Count
        
        if ($beforeCount -gt 0) {
            # Replace all occurrences (case-insensitive)
            $content = $content -replace [regex]::Escape($hexColor), $appColor
            $fileReplacements += $beforeCount
            
            if ($Verbose) {
                Write-Host "  Replaced $beforeCount instances of $hexColor -> $appColor"
            }
        }
    }
    
    # Only write if changes were made
    if ($content -ne $originalContent) {
        if (-not $DryRun) {
            Set-Content -Path $FilePath -Value $content -Force
        }
        
        $script:TotalReplacements += $fileReplacements
        $script:FileChanges += @{
            File = $FilePath
            Count = $fileReplacements
        }
        
        return $fileReplacements
    }
    
    return 0
}

function Main {
    Write-Host "============================================================================================="
    Write-Host "KB SOLAR CRM - COLOR MIGRATION AUTO-SCRIPT (PHASE 3 & 4)"
    Write-Host "============================================================================================="
    Write-Host ""
    
    if ($DryRun) {
        Write-Host "WARNING: DRY RUN MODE - No files will be modified"
        Write-Host ""
    }
    
    Write-Host "Processing Dart files in: $RootPath"
    Write-Host "Total color mappings: $($ColorMappings.Count)"
    Write-Host ""
    
    # Get all dart files
    $dartFiles = Get-AllDartFiles -Path $RootPath
    Write-Host "Found $($dartFiles.Count) Dart files"
    Write-Host ""
    
    # Process each file
    foreach ($file in $dartFiles) {
        $replacementCount = Replace-ColorInFile -FilePath $file.FullName -Mappings $ColorMappings
        
        if ($replacementCount -gt 0) {
            $script:TotalFilesProcessed++
            Write-Host "DONE: $($file.Name): $replacementCount replacements"
        }
    }
    
    # Summary Report
    Write-Host ""
    Write-Host "============================================================================================="
    Write-Host "PHASE 3 & 4 EXECUTION SUMMARY"
    Write-Host "============================================================================================="
    Write-Host ""
    Write-Host "Total Files Processed: $($script:TotalFilesProcessed)"
    Write-Host "Total Replacements: $($script:TotalReplacements)"
    Write-Host ""
    
    if ($script:FileChanges.Count -gt 0) {
        Write-Host "Modified Files (Top 20):"
        $script:FileChanges | Sort-Object Count -Descending | Select-Object -First 20 | ForEach-Object {
            Write-Host "  - $($_.File): $($_.Count) replacements"
        }
    }
    
    Write-Host ""
    Write-Host "Status: $(if ($DryRun) { 'DRY RUN - NO CHANGES MADE' } else { 'COMPLETED' })"
    Write-Host "============================================================================================="
}

# Run main function
Main
