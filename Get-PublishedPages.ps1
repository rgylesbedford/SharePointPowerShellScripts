[CmdletBinding(DefaultParameterSetName="SpecificWebApplication")]
param (
    [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName="SpecificWebApplication")]
    [string] $WebApplicationUrl,

    [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName="AllWebApplications")]
    [switch] $AllWebApplications
)
begin {
    if ($host.Version.Major -gt 1) { $host.Runspace.ThreadOptions = "ReuseThread" }
    if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) { Add-PSSnapin "Microsoft.SharePoint.PowerShell" }
}
process {
    function Get-SPPublishedPagesForWeb {
        param(
            [parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][Microsoft.SharePoint.SPWeb] $web
        )
        process {
            Write-Host "Processing SPWeb $($web.Url)"
            $Web.Lists | Where { $_.BaseTemplate -eq [Microsoft.SharePoint.SPListTemplateType]::WebPageLibrary -or $_.BaseTemplate -eq [Microsoft.SharePoint.SPListTemplateType] 850 } | ForEach-Object {
                $_.Items | ForEach-Object {
                    $info = New-Object PSObject -Property ([Ordered] @{
                        SiteUrl = $web.Site.Url
                        WebUrl = $web.Url
                        WebTemplateId = $web.WebTemplateId
                        ItemUrl = $web.Site.Url + $_["FileRef"]
                        ItemFileName = $_["FileLeafRef"]
                        ItemPageLayout = $_["PublishingPageLayout"]
                        ItemContentType = $_["ContentTypeId"]
                        ItemTitle = $_.Title
                        ItemCreated = $_["Created"]
                        ItemCreatedBy = $_["Author"]
                        ItemModified = $_["Modified"]
                        ItemModifiedBy = $_["Editor"]
                        ItemStatus = $_["_Level"]
                        ItemVersion = "v " + $_["_UIVersionString"]
                        ItemCheckInComment = $_["_CheckinComment"]
                        ItemCheckedOutTo = $_["CheckoutUser"]
                    })
                    Write-Output $info
                }
            }
        }
    }


    $today = Get-Date -format "yyyy-MM-dd-THHmm"
    $fileName = "$PSScriptRoot\Get-PublishedPages-$today.csv"
    Write-Host "Getting PublishedPages" -ForegroundColor Magenta

    switch ($PSCmdlet.ParameterSetName) {
        "SpecificWebApplication" {
            Get-SPWebApplication $WebApplicationUrl | Get-SPContentDatabase | Get-SPSite -Limit ALL | Get-SPPublishedPagesForWeb | Export-Csv $fileName -NoTypeInformation -Encoding UTF8
        }
        "AllWebApplications" {
            Get-SPWebApplication | Get-SPContentDatabase | Get-SPSite -Limit ALL | Get-SPPublishedPagesForWeb | Export-Csv $fileName -NoTypeInformation -Encoding UTF8
        } 
    }

    Write-Host "Done - output saved to $fileName" -ForegroundColor Green
}

end { }