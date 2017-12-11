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
    $fileName = "$PSScriptRoot\LargeLists-$today.csv"



    Get-SPWebApplication $WebApplicationUrl | Get-SPContentDatabase | Get-SPSite -Limit ALL | Get-SPWeb -Limit ALL | ForEach {
        $web = $_

        $webUrl = $web.Url
        $siteUrl = $web.Site.Url

        Write-Host "Processing SPWeb $($webUrl)"

        $web.Lists | Where {$_.ItemCount -gt 3500 -and $_.Hidden -eq $false} | ForEach {
            $list = $_
            $ListId = $list.Id
            
            $listName = $list.Title
            $listFolderCount = $list.Folders.Count
            $listItemCount = $list.ItemCount
            $listUrl = "$($web.Url)/$($list.RootFolder.Url)"
            $ListLastItemModifiedDate = $list.LastItemModifiedDate
            $ListLastItemDeletedDate = $list.LastItemDeletedDate

            $vti_timelastmodified = $list.RootFolder.Properties["vti_timelastmodified"]
            $vti_dirlateststamp = $list.RootFolder.Properties["vti_dirlateststamp"]
            $vti_timecreated = $list.RootFolder.Properties["vti_timecreated"]

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

                $info = New-Object PSObject -Property ([Ordered] @{
                    SiteUrl = $siteUrl
                    WebUrl = $webUrl
                    ListName = $listName
                    ListUrl = $listUrl
                    ListId = $ListId
                    ListItemCount = $listItemCount
                    ListFolderCount = $listFolderCount
                    ListLastItemModifiedDate = $ListLastItemModifiedDate
                    ListLastItemDeletedDate = $ListLastItemDeletedDate
                    ListRootFolder_timelastmodified = $vti_timelastmodified
                    ListRootFolder_dirlateststamp = $vti_dirlateststamp
                    ListRootFolder_timecreated = $vti_timecreated
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
                })
                Write-Output $info
            }
        }
    } | Export-Csv $fileName -NoTypeInformation -Encoding UTF8
}
end {}