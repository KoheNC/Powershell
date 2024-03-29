#Import-Module ActiveDirectory
Import-module MSOnline

$i = 0

import-csv -Path ".\CLIENT-MailboxDelegation.csv" -Delimiter ';' | Foreach { $IdentityPrimarySmtpAddressDYN = $_.IdentityPrimarySmtpAddressDYN

	# Note : ne pas utiliser a couleur YELLOW, car les avertissements thrown par Powershell pour cette CmdLet sont de cette couleur
	
	$i++
	Write-Host "$($i) - Ajout de delegation, permission $($_.AccessRights) sur la BAL $($_.IdentityPrimarySmtpAddressDYN) accordee pour l'utilisateur $($_.TargetPrimarySmtpAddressDYN)" -ForegroundColor green
	Add-MailboxPermission -Identity $_.IdentityPrimarySmtpAddressDYN -User $_.TargetPrimarySmtpAddressDYN -AccessRights $_.AccessRights -AutoMapping:$true
	#>
	
	#Ajout SendAs
	
	if(($_.SendAs -eq "TRUE") -and ($_.UserOrGroup -eq "User")){
		$i++
		Write-Host "$($i) - Ajout de SendAS sur la BAL $($_.IdentityPrimarySmtpAddressDYN) accordee pour l'utilisateur $($_.TargetPrimarySmtpAddressDYN)" -ForegroundColor green
		Add-RecipientPermission $_.IdentityPrimarySmtpAddressDYN -AccessRights SendAs -Trustee $_.TargetPrimarySmtpAddressDYN -Confirm:$false
	}
	#>
	
	<#Ajout SendOnBehalf
	if(($_.SendOnBehalf -eq "TRUE") -and ($_.UserOrGroup -eq "User")){
		$i++
		Write-Host "$($i) - Ajout de SendOnBehalf sur la BAL $($_.IdentityPrimarySmtpAddressDYN) accordee pour l'utilisateur $($_.TargetPrimarySmtpAddressDYN)" -ForegroundColor green
		Set-Mailbox -Identity $_.IdentityPrimarySmtpAddressDYN -GrantSendOnBehalfTo @{add=$($_.TargetPrimarySmtpAddressDYN)}
	}
	#>
	
	#Verification de la creation de toutes les BAL avant de continuer
	<#

	try{
		Invoke-Command -Session $ExchangeSession -ScriptBlock { Get-Mailbox $using:IdentityPrimarySmtpAddressDYN } -ErrorAction Stop | Out-Null
		Write-host "$($i) BAL $($IdentityPrimarySmtpAddressDYN) is ready !" -foregroundColor green
	}catch{
		Write-host "$($i) BAL $($IdentityPrimarySmtpAddressDYN) is NOT ready ! NE PAS CONTINUER LES ETAPES DU SCRIPT" -foregroundColor red
	}
	#>

}