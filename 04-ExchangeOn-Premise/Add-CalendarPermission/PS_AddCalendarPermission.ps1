#Import-module MSOnline

#C:\Scripts\Connect_365.ps1
$compteur = 0

$CalendarPermissionReport = import-csv -Path ".\CalendarPermission.csv" -Delimiter ';' -Encoding UTF8
Foreach ($BAL in $CalendarPermissionReport){
	$compteur +=1
	
	#if((($_.Email -ne "")) -and ($_.Email -ne $null) -or !($_.AccessRights -eq "None")){
	#if(($_.Email -ne "") -and ($_.Email -ne $null) -and ($_.AccessRights -ne "") -and ($_.AccessRights -ne $null)){
	
	if(($BAL.MailboxEmailDYN -ne "") -and ($BAL.MailboxEmailDYN -ne $null) -and ($BAL.AccessRights -ne "") -and ($BAL.AccessRights -ne $null)){
		# Erreur non bloquante.NON TERMINATING ERROR, set stop and exit for logging
		try {
			if($BAL.AccessRights.Contains(","))
				{
					$CalendarPermissions = $BAL.AccessRights.Split(",")
					$Rights = [Microsoft.Exchange.Management.StoreTasks.MailboxFolderAccessRight[]]($CalendarPermissions)
					Add-MailboxFolderPermission -Identity "$($BAL.MailboxEmailDYN):\calendrier" -User $BAL.UserOrGroup -AccessRights $Rights -ErrorAction STOP
					Write-Host "$($compteur) | ADD PERMISSIONS | BAL = $($BAL.MailboxEmailDYN) | GU : $($BAL.UserOrGroup) | RIGHTS = $($BAL.AccessRights)" -Foregroundcolor Green
				}
				else
				{
					$Rights = $BAL.AccessRights
					Add-MailboxFolderPermission -Identity "$($BAL.MailboxEmailDYN):\calendrier" -User $BAL.UserOrGroup -AccessRights $Rights -ErrorAction STOP
					Write-Host "$($compteur) | ADD PERMISSIONS | BAL = $($BAL.MailboxEmailDYN) | GU : $($BAL.UserOrGroup) | RIGHTS = $($BAL.AccessRights)" -Foregroundcolor Green
				}
		} 
		catch [System.Management.Automation.RemoteException] 	
			{
			write-host "$($compteur) Droits deja définis : $($BAL.AccessRights) | BAL : $($BAL.MailboxEmailDYN) | GrantUser : $($BAL.UserOrGroup)" -Foregroundcolor Yellow
			}
		<#catch [System.Management.Automation.Runspaces.RemotingErrorRecord] 	
			{
			write-host "$($compteur) Utilisateur cible inexistant : $($BAL.AccessRights) | BAL : $($BAL.MailboxEmailDYN) | GrantUser : $($BAL.UserOrGroup)" -Foregroundcolor Yellow
			}
			#>
		catch{
			Write-Host "$($compteur) | Exception type = $($_.Exception.getType().Fullname)" -ForegroundColor red
		}
	}
	else
	{
		Write-Host "$($compteur) $($BAL.MailboxEmailDYN)  non trouve ou pas de droits definis" -foreground DarkYellow
	}
}