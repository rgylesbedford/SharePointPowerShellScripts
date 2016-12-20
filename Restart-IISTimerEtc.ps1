param
(
    [Parameter(Mandatory=$false, HelpMessage='-ServiceNames Optional, provide a set of service names to restart.')]
    [Array]$ServiceNames=@("SharePoint Timer Service", "SharePoint Administration", "SharePoint Search Host Controller", "World Wide Web Publishing Service","IIS Admin Service")
)
begin {
    $host.Runspace.ThreadOptions = "ReuseThread"
    Add-PSSnapin "Microsoft.SharePoint.PowerShell"
}
process {
    Write-Host "Attempting to get SharePoint Servers in Farm" -ForegroundColor White;
    Get-SPServer | Where {$_.Role -ne [Microsoft.SharePoint.Administration.SPServerRole]::Invalid} | ForEach-Object {
        $server = $_
        Write-Host "Attempting to restart services on" $server.Name -ForegroundColor White;
        foreach($serviceName in $ServiceNames)
        {
            $serviceInstance = Get-Service -ComputerName $server.Name -Name $serviceName -ErrorAction SilentlyContinue;
            if($serviceInstance -ne $null)
            {
                Write-Host "Attempting to restart service" $serviceName ".." -ForegroundColor White -NoNewline;
                try
                {
                    $restartServiceOutput="";
                    Restart-Service -InputObject $serviceInstance;
                    Write-Host " Done!" -ForegroundColor Green;
                }
                catch
                {
                    Write-Host "Error Occured: " $_.Message;
                }
            }
        }
    }
}
