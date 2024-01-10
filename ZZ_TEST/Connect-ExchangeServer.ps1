$exchangeServer = "exchangeServer.domain.com" # TODO: modify me

try
{
    # Connect to Exchange server
	Write-Host "Adding Exchange PS module" -ForegroundColor Yellow
    $exchangeServer = [System.Net.Dns]::GetHostByName($env:computerName).HostName
    $Session = New-PSSession -connectionURI "http://$exchangeServer/powershell" -ConfigurationName Microsoft.Exchange
    Import-PSSession -session $session -DisableNameChecking
}
finally
{
    # Close the remote session and release resources
    if ($session) { Remove-PSSession -Session $session}
}


#### OR
if (!(Get-Command Get-ExchangeServer -ErrorAction SilentlyContinue))
{
	if (Test-Path "C:\Program Files\Microsoft\Exchange Server\V15\bin\RemoteExchange.ps1")
	{
		. 'C:\Program Files\Microsoft\Exchange Server\V15\bin\RemoteExchange.ps1'
		Connect-ExchangeServer -auto
	} elseif (Test-Path "C:\Program Files\Microsoft\Exchange Server\bin\Exchange.ps1") {
		Add-PSSnapIn Microsoft.Exchange.Management.PowerShell.Admin
		.'C:\Program Files\Microsoft\Exchange Server\bin\Exchange.ps1'
	} else {
		throw "Exchange Management Shell cannot be loaded"
	}
}