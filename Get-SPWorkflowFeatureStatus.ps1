begin {
    if ($host.Version.Major -gt 1) { $host.Runspace.ThreadOptions = "ReuseThread" }
    if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) { Add-PSSnapin "Microsoft.SharePoint.PowerShell" }  

    $PublishingApprovalWorkflowId = "a44d2aa3-affc-4d58-8db4-f4a3af053188"
    $ThreeStateWorkflowId = "fde5d850-671e-4143-950a-87b473922dc7"
    $DispositionApprovalWorkflowId = "c85e5759-f323-4efb-b548-443d2216efb5"
    $SP2007WorkflowsId = "c845ed8d-9ce5-448c-bd3e-ea71350ce45b"
    $SP2010WorkflowsId = "0af5989a-3aea-4519-8ab0-85d91abe39ff"
}
process {

    #region helper functions

    function Get-IsSPSiteFeatureActivated {
        param (
            [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][Microsoft.SharePoint.SPSite] $site,
            [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][guid] $featureId
        )    
        process
        {
            $feature = $site.Features | Where-Object {$_.DefinitionId -eq $featureId}
            if($feature -eq $null) {
                return $false # feature currently deactivated
            }
            else {
                return $true # feature activated
            }
        }
    }

    #endregion helper functions
    
    $today = Get-Date -format "yyyy-MM-dd-THHmm"
    $fileName = "$PSScriptRoot\Get-SPFeatureStatus-$today.csv"
        
    Get-SPWebApplication | Get-SPContentDatabase | Get-SPSite -Limit ALL | % {
        Write-Host "Processing Site: $($_.Url)" -ForegroundColor Yellow
        $info = New-Object PSObject -Property ([Ordered] @{
            SiteCollectionUrl = $_.Url
            PublishingApprovalWorkflow = (Get-IsSPSiteFeatureActivated -site $_ -featureId $PublishingApprovalWorkflowId)
            ThreeStateWorkflow = (Get-IsSPSiteFeatureActivated -site $_ -featureId $ThreeStateWorkflowId)
            DispositionApprovalWorkflow = (Get-IsSPSiteFeatureActivated -site $_ -featureId $DispositionApprovalWorkflowId)
            SP2007Workflows = (Get-IsSPSiteFeatureActivated -site $_ -featureId $SP2007WorkflowsId)
            SP2010Workflows = (Get-IsSPSiteFeatureActivated -site $_ -featureId $SP2010WorkflowsId)
        })
        Write-Output $info
    } | Export-Csv $fileName -NoTypeInformation -Encoding UTF8

    Write-Host "Done - output saved to $fileName" -ForegroundColor Green
}
end { }