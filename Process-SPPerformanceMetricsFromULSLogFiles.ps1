<#

This script will process all .log files in the same location as this script.
It will output a number of .tsv files during the processing of the log files.
The final output will be .csv files that can be used in Excel to create Pivot Tables for analysis.

#>
function Process-SPPerformanceMetricsLogFiles {
    param(
        [string]$sourceFileName,
        [string]$processedFileNameSites,
        [string]$processedFileNameRequests,
        [string]$processedFileNameMetrics,
        [string]$processedFileNameMonitoredMetrics
    )
    process {

        Write-Host "`tProcessing $sourceFileName"

        $regexPatternSiteUrl = "(?:\tLogging Correlation Data.*\tMedium\ \ \tName=Request \((.*?):(.*)\))|(?:\tLogging Correlation Data.*\tMedium\ \ \tSite=(.*)\t)"
        $regexSiteUrl = New-Object Regex($regexPatternSiteUrl, [System.Text.RegularExpressions.RegexOptions]::Compiled)


        $regexPatternPerfMertric = "(?:\tVerbose.*\t(.+):.+WebPart:\ (.+),\ Event:\ (.+),.+with\ duration\ of\ (\d*)ms\t)"
        $regexPerfMertric = New-Object Regex($regexPatternPerfMertric, [System.Text.RegularExpressions.RegexOptions]::Compiled)

        $regexPatternPerfMonitored = "(?:\tLeaving\ Monitored\ Scope\ \((.*)\)\.\ Execution\ Time=(\d*\.{0,1}\d*)\t)"
        $regexPerfMonitored = New-Object Regex($regexPatternPerfMonitored, [System.Text.RegularExpressions.RegexOptions]::Compiled)


        
        Get-Content -path $sourceFileName -ReadCount 1000 | ForEach-Object {
            $sites = @()
            $requests = @()
            $metrics = @()
            $monitoredMetrics = @()

            $_ | % {
                $line = $_

                $matchCollection = $regexSiteUrl.Matches($line)
                if($matchCollection -ne $null) {
                    $count = $matchCollection.Count
                    if($count -gt 0) {
                        $groups = $matchCollection.Groups
                        if($groups[1].Success) {
                            $requests += "$line`t$($groups[1].Value)`t$($groups[2].Value)"
                        } elseif($groups[3].Success) {
                            $sites += "$line`t$($groups[3].Value)"
                        }
                    }
                }

                $matchCollection = $regexPerfMertric.Matches($line)
                if($matchCollection -ne $null) {
                    $count = $matchCollection.Count
                    if($count -gt 0) {
                        $groups = $matchCollection.Groups
                        if($groups[1].Success) {
                            $metrics += "$line`t$($groups[1].Value)`t$($groups[2].Value)`t$($groups[3].Value)`t$($groups[4].Value)`t`t`t"
                        }
                    }
                }


                $matchCollection = $regexPerfMonitored.Matches($line)
                if($matchCollection -ne $null) {
                    $count = $matchCollection.Count
                    if($count -gt 0) {
                        $groups = $matchCollection.Groups
                        if($groups[1].Success) {
                            $monitoredMetrics += "$line`t$($groups[1].Value)`t$($groups[2].Value)`t`t`t"
                        }
                    }
                }
            }

            $metrics | Add-Content -path $processedFileNameMetrics
            $requests | Add-Content -path $processedFileNameRequests
            $sites | Add-Content -path $processedFileNameSites
            $monitoredMetrics | Add-Content -path $processedFileNameMonitoredMetrics
        }
    }
}

$date = (Get-Date).ToString("yyyy-MM-dd")
$processedFileNameSites = "$PSScriptRoot\PerformanceStatsForExcel-Sites-$date.tsv"
$processedFileNameRequests = "$PSScriptRoot\PerformanceStatsForExcel-Requests-$date.tsv"
$processedFileNameMetrics = "$PSScriptRoot\PerformanceStatsForExcel-CustomMetrics-$date.tsv"
$processedFileNameMonitoredMetrics = "$PSScriptRoot\PerformanceStatsForExcel-MonitoredMetrics-$date.tsv"


Set-Content -path $processedFileNameSites -Value "Timestamp`tProcess`tTID`tArea`tCategory`tEventID`tLevel`tMessage`tCorrelation`tSiteUrl"
Set-Content -path $processedFileNameRequests -Value "Timestamp`tProcess`tTID`tArea`tCategory`tEventID`tLevel`tMessage`tCorrelation`tHTTPMethod`tPageUrl"
Set-Content -path $processedFileNameMetrics -Value "Timestamp`tProcess`tTID`tArea`tCategory`tEventID`tLevel`tMessage`tCorrelation`tCodeMethod`tWebPart`tEvent`tDuration (ms)`tSiteUrl`tHTTPMethod`tPageUrl"
Set-Content -path $processedFileNameMonitoredMetrics -Value "Timestamp`tProcess`tTID`tArea`tCategory`tEventID`tLevel`tMessage`tCorrelation`tScope`tExecutionTime`tSiteUrl`tHTTPMethod`tPageUrl"


Write-Host "Processing Log Files"
Get-Item "$PSScriptRoot\*.log" | ForEach-Object {
    $item = $_
    Process-SPPerformanceMetricsLogFiles -sourceFileName $item.FullName -processedFileNameSites $processedFileNameSites -processedFileNameRequests $processedFileNameRequests -processedFileNameMetrics $processedFileNameMetrics -processedFileNameMonitoredMetrics $processedFileNameMonitoredMetrics
}
Write-Host "Done Processing Log Files"



Write-Host "Merging Data..."
Write-Host "`tProcessing SiteUrls..."
$hashSites = @{}

Import-CSV -Path $processedFileNameSites -Delimiter "`t" | Select Correlation, SiteUrl | ForEach-Object {
    $hashSites[$_.Correlation] = $_
}



Write-Host "`tProcessing PageUrls..."
$hashRequests = @{}

Import-CSV -Path $processedFileNameRequests -Delimiter "`t" | Select Correlation, HTTPMethod, PageUrl | ForEach-Object {
    $hashRequests[$_.Correlation] = $_
}



Write-Host "`tProcessing Custom Metrics..."
$processedFileNameCustomMetricsForExport = "$PSScriptRoot\PerformanceStatsForExcel-CustomMetrics-$date.csv"

Import-CSV -Path $processedFileNameMetrics -Delimiter "`t" | Select "Timestamp","Process","TID","Area","Category","Correlation","CodeMethod","WebPart","Event","Duration (ms)","SiteUrl","HTTPMethod","PageUrl" | ForEach-Object {
    $CustomMetric = $_
    $site = $hashSites[$CustomMetric.Correlation]
    $CustomMetric.SiteUrl = $site.SiteUrl

    $request = $hashRequests[$CustomMetric.Correlation] 
    $CustomMetric.HTTPMethod = $request.HTTPMethod
    $CustomMetric.PageUrl = $request.PageUrl
    
    #Cleanup whitespace
    $CustomMetric.PSObject.Properties | % {
        if($_.Value -ne $null) {
            $_.Value = $_.Value.Trim()
        }
    }
    Write-Output $CustomMetric
} | Export-CSV -NoTypeInformation -path $processedFileNameCustomMetricsForExport 



Write-Host "`tProcessing Metrics..."
$processedFileNameMonitoredMetricsForExport = "$PSScriptRoot\PerformanceStatsForExcel-MonitoredMetrics-$date.csv"

Import-CSV -Path $processedFileNameMonitoredMetrics -Delimiter "`t" | Select "Timestamp","Process","TID","Area","Category","Correlation","Scope","ExecutionTime","SiteUrl","HTTPMethod","PageUrl" | ForEach-Object {
    $MonitoredMetric = $_
    
    $site = $hashSites[$MonitoredMetric.Correlation]
    $MonitoredMetric.SiteUrl = $site.SiteUrl

    $request = $hashRequests[$MonitoredMetric.Correlation] 
    $MonitoredMetric.HTTPMethod = $request.HTTPMethod
    $MonitoredMetric.PageUrl = $request.PageUrl
    
    #Cleanup whitespace
    $MonitoredMetric.PSObject.Properties | % {
        if($_.Value -ne $null) {
            $_.Value = $_.Value.Trim()
        }
    }

    Write-Output $MonitoredMetric

} | Export-CSV -NoTypeInformation -path $processedFileNameMonitoredMetricsForExport 



Write-Host "Done Merging Data: $processedFileNameMonitoredMetricsForExport"
