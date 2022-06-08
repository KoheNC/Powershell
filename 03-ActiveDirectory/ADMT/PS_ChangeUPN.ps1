# Change UPN for all users
$i=0

$users = Get-ADUser -filter * -Properties mail -SearchBase "DC=lm2k,DC=fr"

Foreach($user in $users){
	$i++

	# If mail attribute is present
	if($user.mail -ne $null)
	{
		Set-ADUser $user.SAMAccountName  -UserPrincipalName $user.mail
		Write-Host $i" Setting UPN value from: " $($user.userprincipalname) " to: " $($user.mail) -foregroundcolor Green
	}
	<#else
	# No mail is there, create UPN based on SAM
	{
		$UPN = $user.samaccountname + "@example.com"
		Set-ADUser $user.SAMAccountName  -UserPrincipalName $UPN
		Write-Host $i" Setting UPN value from: "$($user.userprincipalname)" to: " $UPN -foregroundcolor Cyan
	}
	#>
}