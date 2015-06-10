Add-PSSnapin "Microsoft.SharePoint.PowerShell"

$adUserName = "domain\username"
$spUserName = "i:0#.w|domain\username"
$userDisplayName = "DisplayName of User"
$spdevvm = "http://portal.gb.local"

#<#
Write-Host "Adding $($adUserName) to Local Administrators group on $($env:COMPUTERNAME)"
$localAdminUserName = $adUserName -replace "\\", "/"
$LocalAdminsGroup = ([ADSI]("WinNT://$($env:COMPUTERNAME)/Administrators,group"))
$LocalAdminsGroup.Add("WinNT://$localAdminUserName")
#>


#<#
Get-SPWeb $spdevvm | % {
    $web = $_

    Write-Host "Adding $($adUserName) as Site Collection Admin to $($spdevvm)"
    $NewAdmin = $web.EnsureUser($adUserName)
    $NewAdmin.IsSiteAdmin = $true
    $NewAdmin.Update()

    Write-Host "Adding $($spUserName) as Site Collection Admin to $($spdevvm)"
    $NewAdmin = $web.EnsureUser($spUserName)
    $NewAdmin.IsSiteAdmin = $true
    $NewAdmin.Update()
}
#>

#<#
$centralAdminUrl = Get-SPWebApplication -IncludeCentralAdministration | where {$_.IsAdministrationWebApplication} | select Url
Get-SPWeb $centralAdminUrl.Url | % {
    $web = $_
    $AdminGroupName = $web.AssociatedOwnerGroup
    $farmAdministratorsGroup = $web.SiteGroups[$AdminGroupName]

    Write-Host "Adding $($apUserName) to Farm Administrators Group"
    $farmAdministratorsGroup.AddUser($adUserName, "", "", "")

    Write-Host "Adding $($spUserName) to Farm Administrators Group"
    $farmAdministratorsGroup.AddUser($spUserName, "", "", "")
    $farmAdministratorsGroup.Update()
}
#>

#<#
Get-SPWebApplication | % {
    $webApp = $_
    
    $FullControl=$webApp.PolicyRoles.GetSpecialRole("FullControl")
    
    Write-Host "Adding Full Control User Policy for $($apUserName) to $($spdevvm) Web Application"
    $Policy1 = $webApp.Policies.Add($adUserName, $userDisplayName)
    $Policy1.PolicyRoleBindings.Add($FullControl)

    Write-Host "Adding Full Control User Policy for $($spUserName) to $($spdevvm) Web Application"
    $Policy2 = $webApp.Policies.Add($spUserName, $userDisplayName)
    $Policy2.PolicyRoleBindings.Add($FullControl)

    $WebApp.Update()
}
#>

#<#
Write-Host "Granting $($apUserName) SPShellAdmin rights"
Add-SPShellAdmin -UserName $adUserName
Get-SPContentDatabase | Add-SPShellAdmin -UserName $adUserName
#>