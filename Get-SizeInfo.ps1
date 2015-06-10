Add-PSSnapin Microsoft.SharePoint.Powershell



$date = (Get-Date).ToString("yyyy-MM-dd")
Get-SPWebApplication | Get-SPContentDatabase | ForEach-Object {
    $db = $_
    $info = New-Object PSObject -Property @{
        Name = $db.DisplayName
        RawSize = $db.DiskSizeRequired
        SizeInGB = $($db.DiskSizeRequired) / 1GB
        SizeInMB = $($db.DiskSizeRequired) / 1MB
    }
    Write-Output $info

} | Export-Csv -NoTypeInformation -Path "$PSScriptRoot\ContentDataBaseSize-$date.csv"




Get-SPWebApplication | Get-SPContentDatabase | Get-SPSite -Limit ALL | ForEach-Object {
    $site = $_
    $info = New-Object PSObject -Property @{
        SiteUrl = $Site.Url
        RawSize = $Site.Usage.Storage
        SizeInGB = $($Site.Usage.Storage) / 1GB
        SizeInMB = $($Site.Usage.Storage) / 1MB
        CompatibilityLevel = $site.CompatibilityLevel
        ContentDatabase = $site.ContentDatabase.DisplayName
    }
    Write-Output $info

} | Export-Csv -NoTypeInformation -Path "$PSScriptRoot\SiteCollectionSize-$date.csv"