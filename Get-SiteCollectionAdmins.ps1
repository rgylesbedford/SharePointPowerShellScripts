begin {
    if ($host.Version.Major -gt 1) { $host.Runspace.ThreadOptions = "ReuseThread" }
    if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) { Add-PSSnapin "Microsoft.SharePoint.PowerShell" }
}
process {

    $today = Get-Date -format "yyyy-MM-dd-THHmm"
    $fileName = "$PSScriptRoot\SiteCollectionAdmins-$today.csv"

    Write-Host "Getting SiteCollectionAdmins" -ForegroundColor Magenta
    
    Get-SPWebApplication | Get-SPContentDatabase | Get-SPSite -Limit ALL | % {
        $site = $_
	    $SiteUrl = $site.Url
        Write-Host "Processing $SiteUrl" -ForegroundColor Yellow

	    $site.RootWeb.SiteAdministrators | % {
		    $user = $_
            if($user -ne $null) {
		        $info = New-Object PSObject -Property ([Ordered] @{
			        SiteUrl = $SiteUrl
			        UserLogin = $user.LoginName
			        UserDisplayName = $user.Name
			        UserEmail = $user.Email
		        })
		        Write-Output $info
            }
	    }
    } | Export-Csv $fileName -NoTypeInformation -Encoding UTF8

    Write-Host "Done - output saved to $fileName" -ForegroundColor Green

}

end {}