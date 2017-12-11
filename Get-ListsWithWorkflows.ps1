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
    $fileName = "$PSScriptRoot\ListsWithWorkflows-$today.csv"
    Write-Host "Getting ListsWithWorkflows" -ForegroundColor Magenta

    Get-SPWebApplication $WebApplicationUrl | Get-SPContentDatabase | Get-SPSite -Limit ALL | Get-SPWeb -Limit ALL | ForEach {
        $web = $_

        $WebUrl = $web.Url
        $SiteUrl = $web.Site.Url

        Write-Host "Processing SPWeb $webUrl" -ForegroundColor Yellow

        $web.Lists | Where {$_.WorkflowAssociations.Count -ge 0} | ForEach {
            $list = $_
        
            $ListName = $list.Title
            $ListId = $list.Id
            $ListUrl = "$($web.Url)/$($list.RootFolder.Url)"
            $ListLastItemModifiedDate = $list.LastItemModifiedDate
            $ListLastItemDeletedDate = $list.LastItemDeletedDate
            $ListItemCount = $list.ItemCount

            $vti_timelastmodified = $list.RootFolder.Properties["vti_timelastmodified"]
            $vti_dirlateststamp = $list.RootFolder.Properties["vti_dirlateststamp"]
            $vti_timecreated = $list.RootFolder.Properties["vti_timecreated"]

            $list.WorkflowAssociations | ForEach {
                $workflow = $_

                $info = New-Object PSObject -Property ([Ordered] @{
                    SiteUrl = $SiteUrl
                    WebUrl = $WebUrl
                    ListUrl = $ListUrl
                    ListName = $ListName
                    ListId = $ListId
                    ListLastItemModifiedDate = $ListLastItemModifiedDate
                    ListLastItemDeletedDate = $ListLastItemDeletedDate
                    ListItemCount = $ListItemCount
                    ListRootFolder_timelastmodified = $vti_timelastmodified
                    ListRootFolder_dirlateststamp = $vti_dirlateststamp
                    ListRootFolder_timecreated = $vti_timecreated
                    WorkflowId = $workflow.Id
                    WorkflowName = $workflow.Name
                    WorkflowDescription = $workflow.Description
                    WorkflowEnabled = $workflow.Enabled
                    WorkflowAllowManual = $workflow.AllowManual
                    WorkflowAutoStartCreate = $workflow.AutoStartCreate
                    WorkflowAutoStartChange = $workflow.AutoStartChange
                    WorkflowCreated = $workflow.Created
                    WorkflowModified = $workflow.Modified
                    WorkflowTaskListId = $workflow.TaskListId
                    WorkflowTaskListTitle = $workflow.TaskListTitle
                    WorkflowTaskListContentTypeId = $workflow.TaskListContentTypeId
                    WorkflowHistoryListId = $workflow.HistoryListId
                    WorkflowHistoryListTitle = $workflow.HistoryListTitle
                    WorkflowIsDeclarative = $workflow.IsDeclarative
                    WorkflowRunningInstances = $workflow.RunningInstances
                    WorkflowInstantiationUrl = $workflow.InstantiationUrl
                })
                Write-Output $info
            }
        }
    } | Export-Csv $fileName -NoTypeInformation -Encoding UTF8

    Write-Host "Done - output saved to $fileName" -ForegroundColor Green
}
end {}