Param([switch]$Step0, [switch]$Step1, [switch]$Step2, [switch]$Step3, [switch]$Step4, [switch]$Step5)
Begin {
    $Password = "zweNAMe8xF"
    $SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
    $fqdn = "gb.local"
    $netbiosName = "GB"
    $SQLPID = "" #Need to copy from sql install files see: http://sqlserver-help.com/2014/06/05/help-how-to-get-product-key-for-sql-server/

}
Process {
    
    #region Steps

    function Step0 {
        process {
            Write-Host -ForegroundColor White " - Installing WindowsFeatures"

            Import-Module ServerManager

            Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
            #Install-WindowsFeature AD-Domain-Services,DNS,DHCP -IncludeManagementTools
            Install-WindowsFeature Desktop-Experience,NET-Framework-Core,Net-Framework-Features,Web-Server,Web-WebServer,Web-Common-Http,Web-Static-Content,Web-Default-Doc,`
                                   Web-Dir-Browsing,Web-Http-Errors,Web-App-Dev,Web-Asp-Net,Web-Net-Ext,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Health,Web-Http-Logging,`
                                   Web-Log-Libraries,Web-Request-Monitor,Web-Http-Tracing,Web-Security,Web-Basic-Auth,Web-Windows-Auth,Web-Filtering,Web-Digest-Auth,`
                                   Web-Performance,Web-Stat-Compression,Web-Dyn-Compression,Web-Mgmt-Tools,Web-Mgmt-Console,Web-Mgmt-Compat,Web-Metabase,Application-Server,`
                                   AS-Web-Support,AS-TCP-Port-Sharing,AS-WAS-Support, AS-HTTP-Activation,AS-TCP-Activation,AS-Named-Pipes,AS-Net-Framework,WAS,WAS-Process-Model,`
                                   WAS-NET-Environment,WAS-Config-APIs,Web-Lgcy-Scripting,Windows-Identity-Foundation,Server-Media-Foundation,Xps-Viewer 

            RunNext -user Administrator -password $password -scriptPath $PSCommandPath -scriptArguments "-Step1"
        }
    }

    function Step1 {
        process{
            Write-Host -ForegroundColor White " - Setting Up Active Directory Forest"
            Import-Module ADDSDeployment

            #<# AD without DNS Server
            Install-ADDSForest -DomainName $fqdn -DomainNetbiosName $netbiosName `
                               -DomainMode "Win2012R2" -ForestMode "Win2012R2" -InstallDNS:$false -NoDnsOnNetwork `
                               -SafeModeAdministratorPassword $SecurePassword -Confirm:$false -NoRebootOnCompletion -LogPath "C:\Logs\ActiveDirectory"
            #>

            <# AD with DNS Server
            Install-ADDSForest -DomainName $fqdn -DomainNetbiosName $netbiosName `
                               -DomainMode "Win2012R2" -ForestMode "Win2012R2" -InstallDNS:$true `
                               -SafeModeAdministratorPassword $SecurePassword -Confirm:$false -NoRebootOnCompletion -LogPath "C:\Logs\ActiveDirectory"
            #>

            #Uninstall-ADDSDomainController –LocalAdministratorPassword (Get-Credential).password –LastDomainControllerInDomain –RemoveApplicationPartitions

            RunNext -user Administrator -password $password -domain $netbiosName -scriptPath $PSCommandPath -scriptArguments "-Step2"
        }
    }

    function Step2 {
        process {
            Import-Module ActiveDirectory 
            $dn = $(Get-ADDomain -Current LoggedOnUser).DistinguishedName

            Write-Host -ForegroundColor White " - Setting up AD Groups"

            New-ADOrganizationalUnit -Name Groups
            New-ADOrganizationalUnit -Name People

            ## Create SQL AD Accounts and Groups

            New-ADOrganizationalUnit -Name SQLServiceAccounts -DisplayName "SQL Service Accounts"
            New-ADOrganizationalUnit -Name SPServiceAccounts -DisplayName "SharePoint Service Accounts"
            
            $sqlSvcOU = (Get-ADOrganizationalUnit -Filter 'Name -eq "SQLServiceAccounts"')
            $spSvcOU = (Get-ADOrganizationalUnit -Filter 'Name -eq "SPServiceAccounts"')
            $GroupsOU = (Get-ADOrganizationalUnit -Filter 'Name -eq "Groups"')
            $sqlAdminsGrp = New-ADGroup -Name SQL_Admins -DisplayName "SQL Administrators" -Path $GroupsOU -GroupScope DomainLocal -GroupCategory Security -PassThru

            Write-Host -ForegroundColor White " - Setting up SQL Users"

            New-ADUser -Name "SQL_Admin" -DisplayName "SQL Administrator" -Path $sqlSvcOU -AccountPassword $SecurePassword -CannotChangePassword $true -PasswordNeverExpires $true -Enabled $true
            New-ADUser -Name "SQL_Agent" -DisplayName "SQL Agent" -Path $sqlSvcOU -AccountPassword $SecurePassword -CannotChangePassword $true -PasswordNeverExpires $true -Enabled $true
            New-ADUser -Name "SQL_Engine" -DisplayName "SQL Engine" -Path $sqlSvcOU -AccountPassword $SecurePassword -CannotChangePassword $true -PasswordNeverExpires $true -Enabled $true
            New-ADUser -Name "SQL_SSIS" -DisplayName "SQL Integration Services" -Path $sqlSvcOU -AccountPassword $SecurePassword -CannotChangePassword $true -PasswordNeverExpires $true -Enabled $true
            New-ADUser -Name "SQL_AS" -DisplayName "SQL Analysis Services" -Path $sqlSvcOU -AccountPassword $SecurePassword -CannotChangePassword $true -PasswordNeverExpires $true -Enabled $true

            Write-Host -ForegroundColor White " - Setting up SP Users"

            New-ADUser -Name "SP_FarmAdmin" -DisplayName "SharePoint Farm Administrator" -Path $spSvcOU -AccountPassword $SecurePassword -CannotChangePassword $true -PasswordNeverExpires $true -Enabled $true
            New-ADUser -Name "SP_Install" -DisplayName "SharePoint Install Account" -Path $spSvcOU -AccountPassword $SecurePassword -CannotChangePassword $true -PasswordNeverExpires $true -Enabled $true
            New-ADUser -Name "SP_WebAppPool" -DisplayName "SharePoint WebApplication Pool" -Path $spSvcOU -AccountPassword $SecurePassword -CannotChangePassword $true -PasswordNeverExpires $true -Enabled $true
            New-ADUser -Name "SP_SrvcAppPool" -DisplayName "SharePoint Service Application Pool" -Path $spSvcOU -AccountPassword $SecurePassword -CannotChangePassword $true -PasswordNeverExpires $true -Enabled $true
            New-ADUser -Name "SP_SearchService" -DisplayName "SharePoint Search Service" -Path $spSvcOU -AccountPassword $SecurePassword -CannotChangePassword $true -PasswordNeverExpires $true -Enabled $true 
            New-ADUser -Name "SP_SearchCrawler" -DisplayName "SharePoint Search Crawler" -Path $spSvcOU -AccountPassword $SecurePassword -CannotChangePassword $true -PasswordNeverExpires $true -Enabled $true
            New-ADUser -Name "SP_UserProfileSync" -DisplayName "SharePoint User Profile Service" -Path $spSvcOU -AccountPassword $SecurePassword -CannotChangePassword $true -PasswordNeverExpires $true -Enabled $true
            New-ADUser -Name "SP_CacheSuperUser" -DisplayName "SharePoint Cache User" -Path $spSvcOU -AccountPassword $SecurePassword -CannotChangePassword $true -PasswordNeverExpires $true -Enabled $true
            New-ADUser -Name "SP_CacheSuperReader" -DisplayName "SharePoint Cache Reader" -Path $spSvcOU -AccountPassword $SecurePassword -CannotChangePassword $true -PasswordNeverExpires $true -Enabled $true
            New-ADUser -Name "SP_ExcelSrvc" -DisplayName "SharePoint Excel Services Application" -Path $spSvcOU -AccountPassword $SecurePassword -CannotChangePassword $true -PasswordNeverExpires $true -Enabled $true
            New-ADUser -Name "SP_VisioSrvc" -DisplayName "SharePoint Visio Graphics Services" -Path $spSvcOU -AccountPassword $SecurePassword -CannotChangePassword $true -PasswordNeverExpires $true -Enabled $true
            New-ADUser -Name "SP_PerfPointSrvc" -DisplayName "SharePoint PerformancePoint Services" -Path $spSvcOU -AccountPassword $SecurePassword -CannotChangePassword $true -PasswordNeverExpires $true -Enabled $true
            #New-ADUser -Name "SP_AccessSrvc" -DisplayName "SharePoint Access Services" -Path $spSvcOU -OtherAttributes $commonUserAttributes
            New-ADUser -Name "SP_WorkflowSrvc" -DisplayName "SharePoint Workflow Services" -Path $spSvcOU -AccountPassword $SecurePassword -CannotChangePassword $true -PasswordNeverExpires $true -Enabled $true
            New-ADUser -Name "SP_C2WTS" -DisplayName "SharePoint Claims to Windows Token Service Account" -Path $spSvcOU -AccountPassword $SecurePassword -CannotChangePassword $true -PasswordNeverExpires $true -Enabled $true



            $sqlAdminsGrp = Get-ADGroup -Identity "SQL_Admins"
            $domainAdmins = Get-ADGroup -Identity "Domain Admins"

            $userProfileSync = Get-ADUser -Filter 'Name -eq "SP_UserProfileSync"'
            $sqlAdmin = Get-ADUser -Filter 'Name -eq "SQL_Admin"'
            $spfarm = Get-ADUser -Filter 'Name -eq "SP_FarmAdmin"'
            $spInstall = Get-ADUser -Filter 'Name -eq "SP_Install"'
            $spC2WTS = Get-ADUser -Filter 'Name -eq "SP_C2WTS"'

            Write-Host -ForegroundColor White " - Setting UserSync AD Permissions"
            DSACLS "$dn" /G "$($env:USERDOMAIN)\$($userProfileSync.SamAccountName):CA;Replicating Directory Changes"

            Write-Host -ForegroundColor White " - Setting SQL Admins"
            $sqlAdminsGrp | Add-ADGroupMember -Members @($sqlAdmin, $spInstall, $domainAdmins)

            Write-Host -ForegroundColor White " - Setting Local Admins"
            $LocalAdminsGroup = ([ADSI]("WinNT://$($env:COMPUTERNAME),computer")).psbase.children.find("administrators")
            $LocalAdminsGroup.Add("WinNT://$($env:USERDOMAIN)/$($sqlAdmin.SamAccountName)")
            $LocalAdminsGroup.Add("WinNT://$($env:USERDOMAIN)/$($spInstall.SamAccountName)")
            $LocalAdminsGroup.Add("WinNT://$($env:USERDOMAIN)/$($spfarm.SamAccountName)")
            $LocalAdminsGroup.Add("WinNT://$($env:USERDOMAIN)/$($userProfileSync.SamAccountName)")
            $LocalAdminsGroup.Add("WinNT://$($env:USERDOMAIN)/$($spC2WTS.SamAccountName)")

            ## If using DNS Server instead of hosts file
            #Write-Host -ForegroundColor White " - Setting DNS Entries"
            #Add-DnsServerResourceRecordCName -Name "*.apps" -HostNameAlias $fqdn -ZoneName $fqdn -Confirm:$false
            #Add-DnsServerResourceRecordCName -Name "portal" -HostNameAlias $fqdn -ZoneName $fqdn -Confirm:$false
            #Add-DnsServerResourceRecordCName -Name "mysites" -HostNameAlias $fqdn -ZoneName $fqdn -Confirm:$false

            Write-Host -ForegroundColor White " - Enabling Remote Desktop..."
            Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
            #New-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0 -PropertyType dword
            Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 1
            #New-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 1 -PropertyType dword
            Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

            RunNext -user SQL_Admin -password $Password -domain $env:USERDOMAIN -scriptPath $PSCommandPath -scriptArguments "-Step3"
        }
    }

    function Step3 {
        process {
            cd "$PSScriptRoot\SQL2014"
            .\Setup.exe /Q /ACTION=Install /PID=$($SQLPID) /FEATURES=SQL,AS,RS,IS,Tools `
                /INSTANCENAME=MSSQLSERVER /IACCEPTSQLSERVERLICENSETERMS /INDICATEPROGRESS `
                /SQLSVCACCOUNT="$($env:USERDOMAIN)\SQL_Engine" /SQLSVCPASSWORD="$Password" /SQLSYSADMINACCOUNTS="$($env:USERDOMAIN)\SQL_Admins" `
                /AGTSVCACCOUNT="$($env:USERDOMAIN)\SQL_Agent" /AGTSVCPASSWORD="$Password" `
                /ISSVCACCOUNT="$($env:USERDOMAIN)\SQL_SSIS" /ISSVCPASSWORD="$Password" `
                /ASSVCACCOUNT="$($env:USERDOMAIN)\SQL_AS" /ASSVCPASSWORD="$Password" /ASSYSADMINACCOUNTS="$($env:USERDOMAIN)\SQL_Admins"  `
                /RSSVCACCOUNT="$($env:USERDOMAIN)\SQL_Engine" /RSSVCPASSWORD="$Password" `
                /UpdateSource="$($PSScriptRoot)\SQL2014-CUs" 

            RunNext -user SP_Install -password $Password -domain $env:USERDOMAIN -scriptPath $PSCommandPath -scriptArguments "-Step4"
        }
    }
    function Step4 {
        process {
            # Login as SP_Install account, so that Step5 can run after user login.
            RunNext -user SP_Install -password $Password -domain $env:USERDOMAIN -scriptPath $PSCommandPath -scriptArguments "-Step5" -afterUserLogin
        }
    }
    function Step5 {
        process {
            ClearAutoLogin
            Write-Host -ForegroundColor White " - Launching AutoSPInstaller"
            
            . "$PSScriptRoot\SP\AutoSPInstaller\AutoSPInstallerLaunch.bat"
        }
    }

    #endregion

    #region helper functions
    function RunNext {
        param(
            [string] $user,
            [string] $password,
            [string] $domain,
            [string] $scriptPath,
            [string] $scriptArguments,
            [switch] $afterUserLogin
        )
        process {
            if($afterUserLogin) {
                New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\" -Name RunOnce -ErrorAction SilentlyContinue | Out-Null
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -Name SPVM -Value "$PSHOME\powershell.exe -Command `"& $scriptPath $scriptArguments`"" -Force | Out-Null
            } else {
                New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\" -Name RunOnce -ErrorAction SilentlyContinue | Out-Null
                Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -Name SPVM -Value "$PSHOME\powershell.exe -Command `"& $scriptPath $scriptArguments`"" -Force | Out-Null
            }
        
            $WinLogonPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
            Set-ItemProperty -Path $WinLogonPath -Name DefaultUserName -Value $user
            Set-ItemProperty -Path $WinLogonPath -Name DefaultPassword -Value $password
            Set-ItemProperty -Path $WinLogonPath -Name DefaultDomainName -Value $domain
            Set-ItemProperty -Path $WinLogonPath -Name AutoAdminLogon -Value 1
            Set-ItemProperty -Path $WinLogonPath -Name ForceAutoLogon -Value 1

            Restart-Computer
        }
    }

    function ClearAutoLogin {
        process {
            $WinLogonPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
            Set-ItemProperty -Path $WinLogonPath -Name AutoAdminLogon -Value 0
            Set-ItemProperty -Path $WinLogonPath -Name ForceAutoLogon -Value 0

            #Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -Name SPVM
        }
    }
    #endregion

    #region main process
    if($Step0) {
        Step0
    } elseif($Step1) {
        Step1
    } elseif($Step2) {
        Step2
    } elseif($Step3) {
        Step3
    } elseif($step4) {
        Step4
    } elseif($step5) {
        Step5
    }
    #endregion
}