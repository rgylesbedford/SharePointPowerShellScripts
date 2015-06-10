Add-PSSnapin Microsoft.SharePoint.Powershell

Get-SPWebApplication | Get-SPSite -Limit ALL | Get-SPWeb -Limit ALL | ForEach {
    $web = $_

    $WebUrl = $web.Url
    $SiteUrl = $web.Site.Url

    $web.Lists | Where {$_.WorkflowAssociations.Count -ge 0} | ForEach {
        $list = $_
        
        $ListName = $list.Title
        $ListUrl = "$($web.Url)/$($list.RootFolder.Url)"
        $ListLastItemModifiedDate = $list.LastItemModifiedDate
        $ListLastItemDeletedDate = $list.LastItemDeletedDate
        $ListItemCount = $list.ItemCount

        $vti_timelastmodified = $list.RootFolder.Properties["vti_timelastmodified"]
        $vti_dirlateststamp = $list.RootFolder.Properties["vti_dirlateststamp"]
        $vti_timecreated = $list.RootFolder.Properties["vti_timecreated"]

        $list.WorkflowAssociations | ForEach {
            $workflow = $_

            $info = New-Object PSObject -Property @{
                SiteUrl = $SiteUrl
                WebUrl = $WebUrl
                ListUrl = $ListUrl
                ListName = $ListName
                ListLastItemModifiedDate = $ListLastItemModifiedDate
                ListLastItemDeletedDate = $ListLastItemDeletedDate
                ListItemCount = $ListItemCount
                ListRootFolder_timelastmodified = $vti_timelastmodified
                ListRootFolder_dirlateststamp = $vti_dirlateststamp
                ListRootFolder_timecreated = $vti_timecreated
                WorkflowName = $workflow.Name
                WorkflowAllowManual = $workflow.AllowManual
                WorkflowAutoStartCreate = $workflow.AutoStartCreate
                WorkflowAutoStartChange = $workflow.AutoStartChange
                WorkflowEnabled = $workflow.Enabled
                WorkflowCreated = $workflow.Created
                WorkflowModified = $workflow.Modified
                WorkflowTaskListTitle = $workflow.TaskListTitle
                WorkflowHistoryListTitle = $workflow.HistoryListTitle
                WorkflowIsDeclarative = $workflow.IsDeclarative
                WorkflowRunningInstances = $workflow.RunningInstances
                WorkflowDescription = $workflow.Description
                
            }
            Write-Output $info
        }
    }
} | Export-Csv "$PSScriptRoot\ListsWithWorkflows.csv" -NoTypeInformation 