function Process-SPSiteUpgradeLogFile {
    param(
        [string]$sourceFileName,
        [string]$processedFileName
    )
    process {

        Write-Host "Processing $sourceFileName"

        $siteUrl = $null
        $regexPattern = "(?:(?:\tExecution Time=)([0-9.]+)(?:\t))|(?:(?:\t\[Execution Time=)([0-9.]+)(?:\] for \[Feature ')(.+)(?:' .*in Web ')(.*)(?:'))|(?:(?:\t\[Execution Time=)([0-9.]+)(?:\] for feature upgrade action )([^ ]+)(?: .* for \[Feature ')(.+)(?:' .*in Web ')(.*)(?:'))"
        $regex = New-Object Regex($regexPattern)

        $siteUrlRegexPattern = "(?:(?:Upgrade Object: SPSite Url=)(.*)(?:\t))"
        $siteUrlRegex = New-Object Regex($siteUrlRegexPattern)


        #$header = "Timestamp`tProcess`tTID`tArea`tCategory`tEventID`tLevel`tMessage`tCorrelation`tExecutionTime`tFeatureUpgradeAction`tFeatureName`tWebUrl`tSiteUrl"
        #Set-Content -path $processedFileName -Value $header

        Get-Content -path $sourceFileName | ForEach-Object {
            $line = $_

            if($siteUrl -eq $null) {
                $siteUrlmatchCollection = $siteUrlRegex.Matches($line)
                if($siteUrlmatchCollection -ne $null) {
                    $count = $siteUrlmatchCollection.Count
                    if($count -gt 0) {
                        $groups = $siteUrlmatchCollection.Groups
                        if($groups[1].Success) {
                            $siteUrl = $groups[1].Value
                        }
                    }
                }
            }

            $matchCollection = $regex.Matches($line)
            if($matchCollection -ne $null) {
                $count = $matchCollection.Count
                if($count -gt 0) {
                    $groups = $matchCollection.Groups
                    if($groups[1].Success) {
                        # Group[1] = ExecutionTime
                        Write-Output "$line`t$($groups[1].Value)`t`t`t`t$siteUrl"
                    } elseif ($groups[2].Success) {
                        # Group[2] = ExecutionTime Group[3] = FeatureName Group[4] = WebUrl
                        Write-Output "$line`t$($groups[2].Value)`t`t$($groups[3].Value)`t$($groups[4].Value)`t$siteUrl"
                    } elseif ($groups[5].Success) {
                        # Group[5] = ExecutionTime Group[6] = FeatureUpgradeAction Group[7] = FeatureName Group[8] = WebUrl
                        Write-Output "$line`t$($groups[5].Value)`t$($groups[6].Value)`t$($groups[7].Value)`t$($groups[8].Value)`t$siteUrl"
                    } else {
                        #ignore line
                    }
                }
            }
        } | Add-Content -path $processedFileName
    }
}

$header = "Timestamp`tProcess`tTID`tArea`tCategory`tEventID`tLevel`tMessage`tCorrelation`tExecutionTime`tFeatureUpgradeAction`tFeatureName`tWebUrl`tSiteUrl"
$processedFileName = "$PSScriptRoot\StatsForExcel.txt"
Set-Content -path $processedFileName -Value $header

Get-Item "$PSScriptRoot\SiteUpgrade-*.log" -exclude "*-processed.log","*-error.log" | ForEach-Object {
    $item = $_
    Process-SPSiteUpgradeLogFile -sourceFileName $item.FullName -processedFileName $processedFileName
}

Write-Host "Done Processing Log Files"

