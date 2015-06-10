begin {
    if ($host.Version.Major -gt 1) { $host.Runspace.ThreadOptions = "ReuseThread" }
    if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) { Add-PSSnapin "Microsoft.SharePoint.PowerShell" }
}
process {
    Get-SPWebApplication | Get-SPContentDatabase | Get-SPSite -Limit ALL | Get-SPWeb -Limit ALL | ForEach {
        $web = $_
        $webUrl = $web.Url
        $siteUrl = $web.Site.Url

        Write-Host "Processing SPWeb $($webUrl)"

        $web.Lists | Where {$_.ItemCount -gt 3000 -and $_.Hidden -eq $false} | ForEach {
            $list = $_       
        
        
            $listName = $list.Title
            $listFolderCount = $list.Folders.Count
            $listItemCount = $list.ItemCount
            $listUrl = "$($web.Url)/$($list.RootFolder.Url)"

            Write-Host "`tChecking List $listName"
        
            $list.Views | Where {$_.Hidden -eq $false} | ForEach {
                $view = $_
                $query = New-Object Microsoft.SharePoint.SPQuery($view)
                $query.RowLimit = 0

                $queryXml = [xml] "<Query>$($view.Query)</Query>"
            
                $HasSorting = $false
                $Sorting = ""
                if($queryXml.Query.OrderBy) {
                    $HasSorting = $true
                    $Sorting = $queryXml.Query.OrderBy.InnerXml
                }

                $HasGroupBy = $false
                $GroupBy = ""
                if($queryXml.Query.GroupBy) {
                    $HasGroupBy = $true
                    $GroupBy = $queryXml.Query.GroupBy.OuterXml
                }

                $HasFilter = $false
                $Filter = ""
                if($queryXml.Query.Where) {
                    $HasFilter = $true
                    $Filter = $queryXml.Query.Where.InnerXml
                }

                $items = $list.GetItems($query)

                $info = New-Object PSObject -Property @{
                    SiteUrl = $siteUrl
                    WebUrl = $webUrl
                    ListName = $listName
                    ListUrl = $listUrl
                    ListItemCount = $listItemCount
                    ListFolderCount = $listFolderCount
                    ViewName = $view.Title                    
                    ViewScope = $view.Scope
                    ViewUrl = "$($web.Url)/$($view.Url)"
                    ViewItemCount = $items.Count
                    ViewQuery = $view.Query
                    ViewSchemaXml = $view.SchemaXml
                    ViewType = $view.Type
                    DefaultView = $view.DefaultView 
                    HasFilters = $HasFilter
                    Filter = $Filter
                    HasGroupBy = $HasGroupBy
                    GroupBy = $GroupBy
                    HasSorting = $HasSorting
                    Sorting = $Sorting
                    HasAggregations = $view.AggregationsStatus
                    Aggregations = $view.Aggregations
                }
                Write-Output $info
            }
        }
    } | Export-Csv "$PSScriptRoot\LargeLists.csv" -NoTypeInformation 
}
end {
    Write-Host "Done"
}