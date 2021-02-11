###########################################################################################################################################
# AVA6
# Adrien LERAYER
# 2020/09/08
#
# SUJET : Lecture de l'OU MIGRATION et affectation des objes présents dans la bonne OU de l'AD
# CONTEXTE : En effectuant la migration des objets du domaine source vers le domaine cible avec ADMT, tous les objets se retrouvent dans l'OU MIGRATION.
# HOW TO PROCEED : 
# 1 - Lecture des objets présents dans l'OU
# 2 - Récupération de leur DN dans le domaine source en se basant sur le sAMAccountName
# 3 - Modification du DN récupéré en introduisant le nouveau domaine
# 4 - Move-Request sur l'objet en cours de traitement grâce au nouveau DN

###########################################################################################################################################
Import-Module ActiveDirectory

# Compteur / Execution path
$i = 0
$iProcessed = 0
$iExcluded = 0
$iNotFound = 0
#$Scriptpath = Split-Path $MyInvocation.MyCommand.Path

# Connexion au domaine source
$SourceUsername     = "LM2K\audit"
$SourcePwd          = Get-Content C:\00-Sources\Migrate-Mailbox\LM2K_PASSWORD.txt | ConvertTo-SecureString
$SourceCredentials  = New-Object -typename System.Management.Automation.PSCredential -argumentlist $SourceUsername, $SourcePwd
$SourceDC           = "DC1.lm2k.fr"

# Traitement de la partie USER
$UsersInOU = Get-ADUser -Filter * -SearchBase "OU=USERS,OU=ADMT-Migration,DC=sante,DC=lan" -Properties DistinguishedName -SearchScope OneLevel

# Pour chaque objet trouve, on recupere son DN, on remplace la partie DC par celle du nouveau domaine, et on supprime la reference à l'objet dans le DN pour pouvoir reutiliser la variable
# Note : on recupere un Object qu'on transforme en String
$UsersInOU | `
ForEach-Object {
		$SAM = $_.SamaccountName
		$TargetUserDN = $_.DistinguishedName
		
		try {
			$DistinguishedName = Get-ADUser -identity $SAM -Properties * -server $SourceDC -credential $SourceCredentials | Select-Object DistinguishedName

			$DistinguishedName = $DistinguishedName.DistinguishedName
			if(($DistinguishedName -like "*OU=Beau Soleil,DC=lm2k,DC=fr") -or ($DistinguishedName -like "*OU=Ambulatoire,DC=lm2k,DC=fr"))
			{
				$DistinguishedName = $DistinguishedName -replace "DC=lm2k,DC=fr","OU=LM-Users,DC=sante,DC=lan"
				
				# Pour pouvoir faire un Move-ADObject, il faut récupérer le DN de son OU
				# Suppression de la partie CN du DN
				$TargetOU = $distinguishedName -creplace "^[^,]*,",""				

				# On enleve l'expiration du MDP
				#Get-ADUser -identity $user.sAMAccountName | Set-ADUser -CannotChangePassword:$true -ChangePasswordAtLogon:$false -PasswordNeverExpires:$True
				$iProcessed++
			}
			else
			{
				$TargetOU = "OU=A-trier,OU=USERS,OU=ADMT-Migration,DC=sante,DC=lan"
				$iExcluded++
			}
			
			# Move-ADObject prend en @param le DN ou le GUID
			Move-ADObject -Identity $TargetUserDN -TargetPath $TargetOU
		}
		catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]{
			#[Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
			$iNotFound++
		}
		Finally
		{
			$i++
		}
	}
Write-Host "Nombre objets traites = "$i -ForegroundColor Yellow
Write-Host "      dont nombre objets deplaces = "$iProcessed -ForegroundColor Green
Write-Host "      dont nombre objets mis dans l'OU par defaut = "$iExcluded -ForegroundColor Red
Write-Host "      dont nombre objets non trouves a la source = "$iNotFound -ForegroundColor Red
#Note : Chr(34) & ////// Chr(34) c'est le caractere double quote par l'ANSI
