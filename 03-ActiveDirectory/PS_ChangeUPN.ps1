# Change UPN for all users in OPAC71 forest
$i=0

$users = Get-ADUser -filter * -Properties mail -SearchBase "OU=opac71,DC=opac71,DC=local"

Foreach($user in $users){
	$i++

	# If mail attribute is present
	if($user.mail -ne $null)
	{
		Set-ADUser $user.SAMAccountName  -UserPrincipalName $user.mail
		Write-Host $i" Setting UPN value from: " $($user.userprincipalname) " to: " $($user.mail) -foregroundcolor Green
	}
	else
	# No mail is there, create UPN based on SAM
	{
		$UPN = $user.samaccountname + "@opacsaoneetloire.fr"
		Set-ADUser $user.SAMAccountName  -UserPrincipalName $UPN
		Write-Host $i" Setting UPN value from: "$($user.userprincipalname)" to: " $UPN -foregroundcolor Cyan
	}
}