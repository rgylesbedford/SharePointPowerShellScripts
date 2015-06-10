Add-PSSnapin Microsoft.SharePoint.Powershell

Get-SPWebApplication | Get-SPSite -Limit ALL | Get-SPWeb -Limit ALL | ForEach {
    $web = $_

    $WebUrl = $web.Url
    $SiteUrl = $web.Site.Url

    $web.Files | Where {$_.CustomizedPageStatus -eq [Microsoft.SharePoint.SPCustomizedPageStatus]::Customized } | ForEach {
        $file = $_

        $info = New-Object PSObject -Property @{
            SiteUrl = $SiteUrl
            WebUrl = $WebUrl
            FileUrl = $file.ServerRelativeUrl
            FileCustomizedPageStatus = $file.CustomizedPageStatus
            FileAuthor = $file.Author
            FileModifiedBy = $file.ModifiedBy
            FileCreated = $file.TimeCreated
            FileModified = $file.TimeLastModified
        }
        Write-Output $info
    }
} | Export-Csv "$PSScriptRoot\CustomizedFiles.csv" -NoTypeInformation 
