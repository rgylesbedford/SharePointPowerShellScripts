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
    function Get-SPWebPartsUsedOnPage {
        param (
            [parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][Microsoft.SharePoint.SPWeb] $web,
            [parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][string] $Url
        )
        process {
            Write-Verbose "Processing Page $($Url)"
            $webpartmanager = $web.GetLimitedWebPartManager($Url, [System.Web.UI.WebControls.WebParts.PersonalizationScope]::Shared)
            $webpartmanager.WebParts | ForEach-Object {
                $info = New-Object PSObject -Property ([Ordered] @{
                    TypeName = $_.GetType().FullName
                    Title = $_.Title
                    WebPartIsClosed = $_.IsClosed
                    WebPartIsVisible = $_.IsVisible
                    WebPartIsHidden = $_.Hidden
                    PageUrl = "$($web.Url)/$Url"
                    WebUrl = $web.Url
                    SiteUrl = $web.Site.Url
                    WebTemplateId = $web.WebTemplateId
                })
                Write-Output $info
            }
        }
    }
    function Get-SPPagesFromWeb {
        param(
            [parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][Microsoft.SharePoint.SPWeb] $web
        )
        process {
            Write-Host "Processing SPWeb $($web.Url)"
            $Web.Lists | Where {$_.BaseType -eq [Microsoft.SharePoint.SPBaseType]::DocumentLibrary -and
                                $_.BaseTemplate -ne [Microsoft.SharePoint.SPListTemplateType]::WebPartCatalog -and
                                <# $_.BaseTemplate -ne [Microsoft.SharePoint.SPListTemplateType]::DesignCatalog -and #>
                                $_.BaseTemplate -ne [Microsoft.SharePoint.SPListTemplateType]::MasterPageCatalog -and
                                $_.BaseTemplate -ne [Microsoft.SharePoint.SPListTemplateType]::ThemeCatalog
                                } | ForEach-Object {
                $_.Items | ForEach-Object {
                   $_.File | Where { $_.Url -like "*.aspx" } | Select Url
                }
            }
            $Web.RootFolder.Files | Where { $_.Url -like "*.aspx" } | Select Url
        }
    }


    $today = Get-Date -format "yyyy-MM-dd-THHmm"
    $fileName = "$PSScriptRoot\Get-SPWebPartInfo-$today.csv"
    Write-Host "Getting SPWebPartsUsedOnPage" -ForegroundColor Magenta

    switch ($PSCmdlet.ParameterSetName) {
        "SpecificWebApplication" {
            Get-SPWebApplication $WebApplicationUrl | Get-SPContentDatabase | Get-SPSite -Limit ALL | Get-SPWeb -Limit All | ForEach-Object {
                Get-SPPagesFromWeb -web $_ | Get-SPWebPartsUsedOnPage -web $_
            } | Export-Csv $fileName -NoTypeInformation -Encoding UTF8
        }
        "AllWebApplications" {
            Get-SPWebApplication | Get-SPContentDatabase | Get-SPSite -Limit ALL | Get-SPWeb -Limit All | ForEach-Object {
                Get-SPPagesFromWeb -web $_ | Get-SPWebPartsUsedOnPage -web $_
            } | Export-Csv $fileName -NoTypeInformation -Encoding UTF8
        } 
    }
    
    Write-Host "Done - output saved to $fileName" -ForegroundColor Green
}

end { }