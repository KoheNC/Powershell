$computers = Import-Csv -Path .\computer.csv -Delimiter ';'
ForEach($computer in $computers){
    $name = "\\"+ $computer.name
    .\psgetsid.exe $name | Out-File .\results.txt -Append
}

## Autre methode
<#
$Error.Clear()
Clear-Host
 
# Initialize Computers List
$computerList = New-Object -TypeName System.Collections.ArrayList
 
# Retrieve ADCOmputers
Import-Module ActiveDirectory
$ADcomputers = @(Get-ADComputer -Filter * -Properties SamAccountName, SID)
 
# Create custom object for each computers
# Add information to this object (ComputerName, DomainSID, LocalSID)
# Add object to Result list
if ($ADcomputers.Count -gt 0)
{
    $i = 0
    foreach ($ADcomputer in $ADcomputers)
    {
        Write-Progress -Activity get-SID -Status Running -Id 0 -PercentComplete (($i/$ADcomputers.Count)*100) -CurrentOperation $computer.ComputerName
 
        $Computer = New-Object -TypeName psobject -Property @{
            "ComputerName"= ([String]$ADcomputer.SamAccountName).Replace('$','')
            "DomainSID"=$ADcomputer.SID
            "LocalSID"=$null
        }
 
        Invoke-Expression -Command (".\PsGetsid.exe " + '\\' + $computer.ComputerName) -ErrorAction SilentlyContinue| Tee-Object -Variable out | Out-Null
        $Computer.LocalSID = ($out | Where-Object{$_ -like "S-1-5*"})
 
        $computerList.Add($Computer) |Out-Null
 
        $i++
    }
}
 
$computerList | Group-Object -Property LocalSID | Format-Table
#>