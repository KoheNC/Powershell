$servers = Get-ADComputer -SearchBase "OU=Servers,DC=xx,DC=yy" -Filter *

$count = ($servers | measure).count
Write-Host "----------------------------------------------------------------------------------------------------------------------------"
Write-Host "$count servers to scan..."
Write-Host "----------------------------------------------------------------------------------------------------------------------------"

$i=1

foreach ($server in $servers){
    $percent = ($i*100/$count)
    Write-progress -activity "Traitement en cours" -status "Effectué:$percent%" -percentcomplete $($i*100/$count)
    $name = $server.Name

    Write-host "Getting services on $name"
    Get-WmiObject win32_service -ComputerName $name -ErrorAction:SilentlyContinue | ?{$_.startname -like '*administra*'} | ft name,startname,startmode -AutoSize

    $i++
}