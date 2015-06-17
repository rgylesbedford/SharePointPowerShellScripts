begin {
    $host.Runspace.ThreadOptions = "ReuseThread"
    Add-PSSnapin "Microsoft.SharePoint.PowerShell"
}
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