param (
    [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [string] $WebApplicationUrl
)
begin {
    if ($host.Version.Major -gt 1) { $host.Runspace.ThreadOptions = "ReuseThread" }
    if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) { Add-PSSnapin "Microsoft.SharePoint.PowerShell" }
}
process {

    $today = Get-Date -format "yyyy-MM-dd-THHmm"
    $fileName = "$PSScriptRoot\ListsWithInfoPath-$today.csv"

    Write-Host "Getting ListsWithInfoPath" -ForegroundColor Magenta

    Get-SPWebApplication $WebApplicationUrl | Get-SPContentDatabase | Get-SPSite -Limit ALL | Get-SPWeb -Limit ALL | % {
        $web = $_

        $WebUrl = $web.Url
        $SiteUrl = $web.Site.Url

        Write-Host "Processing SPWeb $webUrl" -ForegroundColor Yellow

        $web.Lists | ForEach {
            $list = $_
            $ListId = $list.Id

            $ListName = $list.Title
            $ListUrl = "$($web.Url)/$($list.RootFolder.Url)"
            $ListLastItemModifiedDate = $list.LastItemModifiedDate
            $ListLastItemDeletedDate = $list.LastItemDeletedDate
            $ListItemCount = $list.ItemCount


            $vti_timelastmodified = $list.RootFolder.Properties["vti_timelastmodified"]
            $vti_dirlateststamp = $list.RootFolder.Properties["vti_dirlateststamp"]
            $vti_timecreated = $list.RootFolder.Properties["vti_timecreated"]

            if($list.BaseTemplate -eq [Microsoft.SharePoint.SPListTemplateType]::XMLForm) {
                $info = New-Object PSObject -Property ([Ordered] @{
                    SiteUrl = $SiteUrl
                    WebUrl = $WebUrl
                    ListUrl = $ListUrl
                    ListName = $ListName
                    ListId = $ListId
                    ListType = $list.BaseTemplate
                    InfoPathType = "FormLibrary"
                    ListLastItemModifiedDate = $ListLastItemModifiedDate
                    ListLastItemDeletedDate = $ListLastItemDeletedDate
                    ListItemCount = $ListItemCount
                    ListRootFolder_timelastmodified = $vti_timelastmodified
                    ListRootFolder_dirlateststamp = $vti_dirlateststamp
                    ListRootFolder_timecreated = $vti_timecreated
                })
                Write-Output $info
            }
            else {
                $list.ContentTypes | ForEach {
                    $contentType = $_

                    $hasInfoPathNewItemForm = $contentType.NewFormUrl -like "*newifs.aspx"
                    $hasInfoPathEditItemForm = $contentType.EditFormUrl -like "*editifs.aspx"
                    $hasInfoPathDisplayForm = $contentType.DisplayFormUrl -like "*displayifs.aspx"

                    if($hasInfoPathNewItemForm -or $hasInfoPathEditItemForm -or $hasInfoPathDisplayForm) {
                        $info = New-Object PSObject -Property ([Ordered] @{
                            SiteUrl = $SiteUrl
                            WebUrl = $WebUrl
                            ListUrl = $ListUrl
                            ListName = $ListName
                            ListId = $ListId
                            ListType = $list.BaseTemplate
                            InfoPathType = "ListWithInfoPath"
                            ListLastItemModifiedDate = $ListLastItemModifiedDate
                            ListLastItemDeletedDate = $ListLastItemDeletedDate
                            ListItemCount = $ListItemCount
                            ListRootFolder_timelastmodified = $vti_timelastmodified
                            ListRootFolder_dirlateststamp = $vti_dirlateststamp
                            ListRootFolder_timecreated = $vti_timecreated
                            ContentTypeName = $contentType.Name
                            ContentTypeHasInfoPathNewItemForm = $hasInfoPathNewItemForm
                            ContentTypeHasInfoPathEditItemForm = $hasInfoPathEditItemForm
                            ContentTypeHasInfoPathDisplayForm = $hasInfoPathDisplayForm
                        })
                        Write-Output $info
                    }
                }
            }
        }
    } | Export-Csv $fileName -NoTypeInformation -Encoding UTF8

    Write-Host "Done - output saved to $fileName" -ForegroundColor Green
}

end {}