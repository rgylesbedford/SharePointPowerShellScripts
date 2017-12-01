<#
.SYNOPSIS
Clear the Configuration Cache in a SharePoint 2010, 2013, or 2016 farm
   
.DESCRIPTION
Clear-SPConfigCache.ps1 will:
 1. Stop the SharePoint Timer Service on all servers in the farm
 2. Delete all xml files in the configuration cache folder on all servers in the farm
 3. Copy the existing cache.ini files as a backup
 4. Clear the cache.ini files and reset them to a value of 1
 5. Start the SharePoint Timer Service on all servers in the farm
 
Clear-SPConfigCache.ps1 will work in either single-server and multi-server farms.
 
Run in an elevated SharePoint Management Shell
 
Author: Jason Warren
 
.LINK
 http://jasonwarren.ca/ClearSPConfigCache ClearSPConfigCache.ps1
  
.EXAMPLE
 .\Clear-SPConfigCache.ps1
  
.INPUTS
None. Clear-SPConfigCache.ps1 does not take any input.
 
.OUTPUTS
Text output that describes the current task being performed.
 
#>
 

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction Stop

$farm = Get-SPFarm
$ConfigDB = Get-SPDatabase | where {$_.Name -eq $Farm.Name}
 
# Configuration Cache is stored in %PROGRAMDATA\Microsoft\SharePoint\Config\[Config ID GUID]
# %PROGRAMDATA% is C:\ProgramData by default, it is assumed it's in the same location on all servers in the farm
#   i.e. if it's X:\ProgramData on one server, it will be X:\ProgramData on the others
# We'll be connecting via UNC paths, so we'll also change the returned DRIVE: to DRIVE$
$ConfigPath = "$(($env:PROGRAMDATA).Replace(':','$'))\Microsoft\SharePoint\Config\$($ConfigDB.Id.Guid)"
 
# Stop the timer service on all farm servers
$TimerServiceName = "SPTimerV4"
foreach ($server in $farm.TimerService.Instances.Server) {
    Write-Output "Stopping $TimerServiceName on $($server.Address)..."
    $service = Get-Service -ComputerName $server.Address -Name $TimerServiceName
    Stop-Service -InputObject $service -Verbose
} # Foreach server
 
 
$TimeStamp = Get-Date -Format "yyyymmddhhmmssms"
 
# Clear and reset the cache on each server in the farm
foreach ($server in $farm.TimerService.Instances.Server) {
 
    Write-Output $server.Address
     
    # build the UNC path e.g. \\server\X$\ProgramData\Microsoft\SharePoint\Config\00000000-0000-0000-0000-000000000000
    $ServerConfigPath = "\\$($server.Address)\$($ConfigPath)"
     
    # Delete the XML files
    Write-Output "Remove XML files: $ServerConfigPath..."
    Remove-Item -Path "$ServerConfigPath\*.xml"
     
    # Backup the old cache.ini
    Write-Output "Backup $ServerConfigPath\cache.ini..."
    Copy-Item -Path "$ServerConfigPath\cache.ini" -Destination "$ServerConfigPath\cache.ini.$TimeStamp"
     
    # Save the value of "1" to cache.ini
    Write-Output "Set cache.ini to '1'..."
    "1" | Out-File -PSPath "$ServerConfigPath\cache.ini"
 
    Write-Output ""
     
} #foreach server
 
#Start the timer service on all farm servers
foreach ($server in $farm.TimerService.Instances.Server) {
    Write-Output "Starting $TimerServiceName on $($server.Address)..."
    $service = Get-Service -ComputerName $server.Address -Name $TimerServiceName
    Start-Service -InputObject $service -Verbose
     
}
