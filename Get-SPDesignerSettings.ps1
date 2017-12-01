begin {
    if ($host.Version.Major -gt 1) { $host.Runspace.ThreadOptions = "ReuseThread" }
    if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) { Add-PSSnapin "Microsoft.SharePoint.PowerShell" }
}
process {

    $today = Get-Date -format "yyyy-MM-dd-THHmm"
    $fileName1 = "$PSScriptRoot\SPWebApplicationDesignerSettings-$today.csv"
    Write-Host "Getting SPWebApplicationDesignerSettings" -ForegroundColor Magenta
    Get-SPWebApplication | % {
        $webApp = $_

        Write-Host "Processing SPWebApplicationDesignerSettings for $($webApp.GetResponseUri([Microsoft.SharePoint.Administration.SPUrlZone]::Default).AbsoluteUri)"

        $info = New-Object PSObject -Property ([Ordered] @{
            WebAppUrl = $webApp.GetResponseUri([Microsoft.SharePoint.Administration.SPUrlZone]::Default).AbsoluteUri
            AllowDesigner = $webApp.AllowDesigner
            AllowCreateDeclarativeWorkflow = $webApp.AllowCreateDeclarativeWorkflow
            AllowMasterPageEditing = $webApp.AllowMasterPageEditing
            AllowRevertFromTemplate = $webApp.AllowRevertFromTemplate
            AllowSaveDeclarativeWorkflowAsTemplate = $webApp.AllowSaveDeclarativeWorkflowAsTemplate
            AllowSavePublishDeclarativeWorkflow = $webApp.AllowSavePublishDeclarativeWorkflow
            ShowURLStructure = $webApp.ShowURLStructure
        })
        Write-Output $info
    } | Export-Csv $fileName1 -NoTypeInformation -Encoding UTF8
    Write-Host "Done Getting SPWebApplicationDesignerSettings" -ForegroundColor Yellow



    $fileName2 = "$PSScriptRoot\SPSiteDesignerSettings-$today.csv"
    Write-Host "Getting SPSiteDesignerSettings" -ForegroundColor Magenta
    Get-SPWebApplication | Get-SPContentDatabase | Get-SPSite -Limit ALL | % {
        $site = $_
        Write-Host "Processing SPSiteDesignerSettings for $($Site.Url)"
    
        $info = New-Object PSObject -Property ([Ordered] @{
            SiteUrl = $Site.Url
            AllowDesigner = $site.AllowDesigner
            AllowCreateDeclarativeWorkflow = $site.AllowCreateDeclarativeWorkflow
            AllowSaveDeclarativeWorkflowAsTemplate = $site.AllowSaveDeclarativeWorkflowAsTemplate
            AllowSavePublishDeclarativeWorkflow = $site.AllowSavePublishDeclarativeWorkflow
            AllowMasterPageEditing = $site.AllowMasterPageEditing
            AllowRevertFromTemplate = $site.AllowRevertFromTemplate
            ShowURLStructure = $site.ShowURLStructure
        })
        Write-Output $info
    } | Export-Csv $fileName2 -NoTypeInformation -Encoding UTF8
    Write-Host "Done Getting SPSiteDesignerSettings" -ForegroundColor Yellow


    $fileName3 = "$PSScriptRoot\SPWebDesignerSettings2007-$today.csv"
    Write-Host "Getting SPWebDesignerSettings2007" -ForegroundColor Magenta
    Get-SPWebApplication | Get-SPContentDatabase | Get-SPSite -Limit ALL | Get-SPWeb -Limit ALL | % {
        $web = $_
        Write-Host "Processing SPWebDesignerSettings2007 for $($web.Url)"
        $key = "vti_disablewebdesignfeatures2"

        if($web.AllProperties.ContainsKey($key)) {
            $info = New-Object PSObject -Property ([Ordered] @{
                SiteUrl = $web.Site.Url
                WebUrl = $web.Url
                vti_disablewebdesignfeatures2 = $web.AllProperties[$key]
            })
            Write-Output $info
        }
    } | Export-Csv $fileName3 -NoTypeInformation -Encoding UTF8
    Write-Host "Done Getting SPWebDesignerSettings2007" -ForegroundColor Yellow
}
end {
    Write-Host "Done" -ForegroundColor Green
}