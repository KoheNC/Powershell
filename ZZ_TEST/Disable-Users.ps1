$DisabledAccountUnit = "OU=AVA-Disabled,DC=avacloud,DC=lan"
$CurrentDate = Get-Date -Format "yyyy/MM/dd"

## Expired user accounts
$expiredAccounts = Get-ADUser -Filter * -Properties * -SearchBase "OU=AVA-Users,OU=AVA6GROUP,DC=avacloud,DC=lan"| ? {($_.AccountExpirationDate -NE $NULL -AND $_.AccountExpirationDate -LT (Get-Date)) } | Select-Object Name,SamAccountName,UserPrincipalName,Mail,DistinguishedName,Description,Company,@{N="OU";E={$_.canonicalName -ireplace '\/[^\/]+$',''}}

$expiredAccounts | Foreach-Object{
	# Append description with exit date, then disable and move the user
	if($null -eq $_.description){
		$desc = "Disabled on $CurrentDate"
	}else{
		$desc = $_.description + "| Disabled on $CurrentDate"
	}
	
	Set-ADUser $_.samaccountname -Enabled $false -Description $desc
	
	Move-ADObject -Identity $_.distinguishedName -TargetPath $DisabledAccountUnit
	Write-host "User $($a.Name) moved to the Disabled User OU :) !"
}