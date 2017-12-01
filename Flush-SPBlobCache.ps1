[CmdletBinding(DefaultParameterSetName="SpecificWebApp")]
param (
    [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName="SpecificWebApp")] [string] $WebApplicationUrl,
    [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName="AllWebApps")] [switch] $AllWebApplications
)
begin {
    if ($host.Version.Major -gt 1) { $host.Runspace.ThreadOptions = "ReuseThread" }
    if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) { Add-PSSnapin "Microsoft.SharePoint.PowerShell" }
}
process {
    switch ($PSCmdlet.ParameterSetName) {
        "SpecificWebApp"  {
            Get-SPWebApplication $WebApplicationUrl | % {
                Write-Host "Flushing the Blob Cache for:" $_
                [Microsoft.SharePoint.Publishing.PublishingCache]::FlushBlobCache($_)         
            }
            Write-Host "Done"
        }
        "AllWebApps"  {
            Get-SPWebApplication | % {
                Write-Host "Flushing the Blob Cache for:" $_
                [Microsoft.SharePoint.Publishing.PublishingCache]::FlushBlobCache($_)          
            }
            Write-Host "Done"
        } 
    }
}