Add-PSSnapin Microsoft.SharePoint.Powershell

Get-SPWebApplication | Get-SPSite -Limit ALL | Get-SPWeb -Limit ALL | ForEach {
    $web = $_

    $WebUrl = $web.Url
    $SiteUrl = $web.Site.Url

    $web.Lists | Where {$_.BaseType -eq [Microsoft.SharePoint.SPBaseType]::DocumentLibrary -and
                        $_.BaseTemplate -ne [Microsoft.SharePoint.SPListTemplateType]::WebPartCatalog -and
                        $_.BaseTemplate -ne [Microsoft.SharePoint.SPListTemplateType]::DesignCatalog -and
                        $_.BaseTemplate -ne [Microsoft.SharePoint.SPListTemplateType]::MasterPageCatalog -and
                        $_.BaseTemplate -ne [Microsoft.SharePoint.SPListTemplateType]::ThemeCatalog
                        } | ForEach {
        $list = $_

        $ListName = $list.Title
        $ListUrl = "$($web.Url)/$($list.RootFolder.Url)"
        $ListLastItemModifiedDate = $list.LastItemModifiedDate
        $ListLastItemDeletedDate = $list.LastItemDeletedDate
        $ListItemCount = $list.ItemCount

        $vti_timelastmodified = $list.RootFolder.Properties["vti_timelastmodified"]
        $vti_dirlateststamp = $list.RootFolder.Properties["vti_dirlateststamp"]
        $vti_timecreated = $list.RootFolder.Properties["vti_timecreated"]

        $list.Items | ForEach {
            $item = $_
            $item.File | Where { $_.Url -like "*.css" -or $_.Url -like "*.js" }  | ForEach {
                $file = $_

                $info = New-Object PSObject -Property @{
                    SiteUrl = $SiteUrl
                    WebUrl = $WebUrl
                    ListName = $ListName
                    ListUrl = $ListUrl
                    ListLastItemModifiedDate = $ListLastItemModifiedDate
                    ListLastItemDeletedDate = $ListLastItemDeletedDate
                    ListItemCount = $ListItemCount
                    ListRootFolder_timelastmodified = $vti_timelastmodified
                    ListRootFolder_dirlateststamp = $vti_dirlateststamp
                    ListRootFolder_timecreated = $vti_timecreated
                    FileUrl = $file.ServerRelativeUrl
                    FileAuthor = $file.Author
                    FileModifiedBy = $file.ModifiedBy
                    FileCreated = $file.TimeCreated
                    FileModified = $file.TimeLastModified
                }
                Write-Output $info
            }
        }
    }
} | Export-Csv "$PSScriptRoot\CSSandJSFiles.csv" -NoTypeInformation 
