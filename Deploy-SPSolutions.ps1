begin {
    $webApplicationUrl = "http://spdev.local"
    $wsps = @(
        "RGB.SP2013.Administration.wsp",
        "RGB.SP2013.MyProject.wsp"
    )
    $wspLocation = "$PSScriptRoot"
    $sleepDurationInSeconds = 15

    $host.Runspace.ThreadOptions = "ReuseThread"
    Add-PSSnapin "Microsoft.SharePoint.PowerShell"

    #region helper functions

    function Uninstall-RGBSPSolution {
        param(
            [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][string] $wspName
        )
        process {
            Start-SPAssignment -Global
            $wsp = Get-SPSolution $wspName -ErrorAction silentlycontinue
            if ($wsp -ne $null -and $wsp.Deployed) {
                Write-Output "Uninstalling $($wsp.Name)"
                if ($wsp.ContainsWebApplicationResource) { 
                    Uninstall-SPSolution $wsp -AllWebApplications -Confirm:$false
                }
                else {
                    Uninstall-SPSolution $wsp -Confirm:$false
                }

                Start-Sleep $sleepDurationInSeconds
                $wsp = Get-SPSolution $wspName -ErrorAction silentlycontinue
                while ($wsp.JobExists -eq $true) {
                    Write-Verbose "Waiting for Uninstall to complete for $wspName" -Verbose
                    Start-Sleep $sleepDurationInSeconds
                    $wsp = Get-SPSolution $wspName
                }
            }
            Stop-SPAssignment -Global
        }
    }

    function Add-RGBSPSolution {
        param(
            [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][string] $wspName,
            [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][string] $LiteralPath
        )
        process {
            Start-SPAssignment -Global

            $wsp = Get-SPSolution $wspName -ErrorAction silentlycontinue
            if($wsp -ne $null) {
                while ($wsp.JobExists -eq $true) {
                    Write-Verbose "Waiting for Remove to complete for $wspName" -Verbose
                    Start-Sleep $sleepDurationInSeconds
                    $wsp = Get-SPSolution $wspName
                }
            }

            Write-Output "Adding Solution $wspName"
            $solution = Add-SPSolution -LiteralPath $LiteralPath -Confirm:$false 
            Stop-SPAssignment -Global
        }
    }

    function Remove-RGBSPSolution {
        param(
            [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][string] $wspName,
            [switch]$force
        )
        process {
            Start-SPAssignment -Global
            $wsp = Get-SPSolution $wspName -ErrorAction silentlycontinue
            if($wsp -ne $null) {
                while ($wsp.JobExists -eq $true) {
                    Write-Verbose "Waiting for Uninstall to complete for $wspName" -Verbose
                    Start-Sleep $sleepDurationInSeconds
                    $wsp = Get-SPSolution $wspName
                }

                Write-Output "Removing $wspName"
                Remove-SPSolution -Identity $wspName -Confirm:$false -Force:$force.IsPresent
            }
            Stop-SPAssignment -Global
        }
    }

    function Install-RGBSPSolution {
        param(
            [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)][string] $wspName,
            [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)][string] $webApplicationUrl = $null,
            [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)][string] $CompatibilityLevel = "15",
            [switch]$force
        )
        process {
            Start-SPAssignment -Global
               
            if($webApplicationUrl -ne $null -and $webApplicationUrl -ne "") {
                Write-Output "Installing Solution $wspName to $webApplicationUrl with CompatibilityLevel $CompatibilityLevel"
                Install-SPSolution -Identity $wspName -WebApplication $webApplicationUrl -GACDeployment -CompatibilityLevel $CompatibilityLevel -Force:$force.IsPresent
            } else {
                Write-Output "Installing Solution $wspName with CompatibilityLevel $CompatibilityLevel"
                Install-SPSolution -Identity $wspName -GACDeployment -CompatibilityLevel $CompatibilityLevel -Force:$force.IsPresent
            }
        
            Start-Sleep $sleepDurationInSeconds
            $wsp = Get-SPSolution $wspName -ErrorAction silentlycontinue
            if($wsp -ne $null) {
                while ($wsp.JobExists -eq $true) {
                    Write-Verbose "Waiting for install to complete for $wspName" -Verbose
                    Start-Sleep $sleepDurationInSeconds
                    $wsp = Get-SPSolution $wspName -ErrorAction silentlycontinue
                }
            }
            Stop-SPAssignment -Global
        }
    }

    function Update-RGBSPSolution {
        param(
            [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)][string] $wspName,
            [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)][string] $LiteralPath,
            [switch]$GACDeployment,
            [switch]$force
        )
        process {
            Start-SPAssignment -Global
            
            Write-Output "Updating Solution $wspName"
            Update-SPSolution -Identity $wspName -LiteralPath $LiteralPath -GACDeployment:$GACDeployment.IsPresent -Force:$force.IsPresent
        
            Start-Sleep $sleepDurationInSeconds
            $wsp = Get-SPSolution $wspName -ErrorAction silentlycontinue
            if($wsp -ne $null) {
                while ($wsp.JobExists -eq $true) {
                    Write-Verbose "Waiting for update to complete for $wspName" -Verbose
                    Start-Sleep $sleepDurationInSeconds
                    $wsp = Get-SPSolution $wspName -ErrorAction silentlycontinue
                }
            }
            Stop-SPAssignment -Global
        }
    }

    function Restart-SPTimerService {
        process {
            Get-SPFarm | ForEach {
                $farm = $_
                $farm.TimerService.Instances | ForEach {

                    $timerServiceInstance = $_
                    Write-Output "Stopping $($timerServiceInstance.TypeName) on $($timerServiceInstance.Server.Name)"
                    $timerServiceInstance.Stop()

                    Write-Output "Starting $($timerServiceInstance.TypeName) on $($timerServiceInstance.Server.Name)"
                    $timerServiceInstance.Start()
                }
            }
        }
    }

    #endregion helper functions
}
process {
    #<#
    #region uninstall, remove, add, install

    $wsps | Uninstall-RGBSPSolution
    $wsps | Remove-RGBSPSolution
    $wsps | ForEach-Object {
        $wspName = $_
        Add-RGBSPSolution -wspName $wspName -LiteralPath "$wspLocation\$wspName"
    }

    <#
    $wspName = "RGB.SP2013.Administration.wsp"
    if($wsps.Contains($wspName)) {
        Install-RGBSPSolution -wspName $wspName
    }#>

    $wspName = "RGB.SP2013.BI.Branding.wsp"
    if($wsps.Contains($wspName)) {
        Install-RGBSPSolution -wspName $wspName -webApplicationUrl $webApplicationUrl
    }

    
    #endregion uninstall, remove, add, install
    #>

    <#
    #region update

    $wspName = "RGB.SP2013.MyProject.wsp"
    Update-RGBSPSolution -wspName $wspname -LiteralPath "$wspLocation\$wspName" -GACDeployment

    Restart-SPTimerService

    #endregion update
    #>
}