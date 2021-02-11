###########################################################################################################################################
# AVA6
# Adrien LERAYER
# 2020/09/08
#
# SUJET : Lecture de l'OU MIGRATION et affectation des groupes presents dans la bonne OU de l'AD
# CONTEXTE : En effectuant la migration des objets du domaine source vers le domaine cible avec ADMT, tous les objets se retrouvent dans l'OU MIGRATION.
# HOW TO PROCEED : 
# 1 - Lecture des objets presents dans l'OU
# 2 - Recuperation de leur DN dans le domaine source en se basant sur le sAMAccountName
# 3 - Modification du DN recupere en introduisant le nouveau domaine
# 4 - Move-Request sur l'objet en cours de traitement grace au nouveau DN

###########################################################################################################################################
IImport-Module ActiveDirectory

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

# Traitement de la partie GROUP
$GroupsInOU = Get-ADGroup -Filter * -SearchBase "OU=GROUPS,OU=ADMT-Migration,DC=sante,DC=lan" -Properties *

# Pour chaque objet trouvé, on récupère son DN, on remplace la partie DC par celle du nouveau domaine, et on supprime la référence à l'objet dans le DN pour pouvoir réutiliser la variable
# Note : on récupère un Object qu'on transforme en String
$GroupsInOU | `
ForEach-Object {
		$SAM = $_.SamaccountName
		$TargetUserDN = $_.DistinguishedName
		
		try {
			$DistinguishedName = Get-ADUser -identity $SAM -Properties * -server $SourceDC -credential $SourceCredentials | Select-Object DistinguishedName

			$DistinguishedName = $DistinguishedName.DistinguishedName
			if($DistinguishedName -like "*OU=Beau Soleil,DC=lm2k,DC=fr")
			{
				#$DistinguishedName = $DistinguishedName -replace "DC=lm2k,DC=fr","OU=LM-Groups,DC=sante,DC=lan"
				$TargetOU = "OU=CBS,OU=LM-Groups,DC=sante,DC=lan"
				
				#$TargetOU = $distinguishedName -creplace "^[^,]*,",""				

				$iProcessed++
			}
			elseif($DistinguishedName -like "*OU=Ambulatoire,DC=lm2k,DC=fr")
			{
				#$DistinguishedName = $DistinguishedName -replace "DC=lm2k,DC=fr","OU=LM-Groups,DC=sante,DC=lan"
				$TargetOU = "OU=AMB,OU=LM-Groups,DC=sante,DC=lan"

				#$TargetOU = $distinguishedName -creplace "^[^,]*,",""				

				$iProcessed++
			}
			else
			{
				$TargetOU = "OU=A-trier,OU=GROUPS,OU=ADMT-Migration,DC=sante,DC=lan"
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






foreach ($groupe in $GroupsInOu)
	{
		$DistinguishedName = Get-ADGroup -identity $groupe.sAMAccountName -Properties * -server DC1.pasteur -credential $cred | Select-Object DistinguishedName | Out-String
        $DistinguishedName = $DistinguishedName -replace "DC=pasteur","DC=cp,DC=lan"
        		
		# Pour pouvoir faire un Move-ADObject, il faut récupérer le DN de son OU
		# Suppression de la partie CN du DN
		$OUDN = $distinguishedName -creplace "^[^,]*,",""
		# On recupere le DN de l'utilisateur courant pour pouvoir le déplacer
		# Move-ADObject prend en @param le DN ou le GUID
		$objCP = Get-ADGroup -identity $groupe.sAMAccountName -Properties DistinguishedName
		Move-ADObject -Identity $objCP.distinguishedName -TargetPath $OUDN

        # Affichage utilisateur
        $nbObjets += 1
        Write-Host "Nombre objets trait�s = " $nbObjets -ForegroundColor Green
	}