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
                New-Object PSObject -Property @{
				    TypeName = $_.GetType().FullName
				    Title = $_.Title
                    WebPartIsClosed = $_.IsClosed
                    WebPartIsVisible = $_.IsVisible
                    WebPartIsHidden = $_.Hidden
				    PageUrl = "$($web.Url)/$Url"
                    WebUrl = $web.Url
                    SiteUrl = $web.Site.Url
                    WebTemplateId = $web.WebTemplateId
                }
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
                                $_.BaseTemplate -ne [Microsoft.SharePoint.SPListTemplateType]::DesignCatalog -and
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

    Get-SPWebApplication | Get-SPContentDatabase | Get-SPSite -Limit All | Get-SPWeb -Limit All | ForEach-Object {
        Get-SPPagesFromWeb -web $_ | Get-SPWebPartsUsedOnPage -web $_
    } | Export-CSV "$PSScriptRoot\SPWebPartInfoResults.csv" -NoTypeInformation
}

end {
    Write-Host "Done"
}