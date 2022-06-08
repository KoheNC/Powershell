#######################################################################
#Script de changement d'UPN en prenom.nom@example.com
#
# 18/07/2016 - Mathieu CROZIER - AVA6
#
#Fonctionnement du script:
#  -Lancer le script depuis une invite de commande Powershell : C:\Scripts\Changement UPN - OneDrive\ChangeUsersUPN.ps1
#  -Choisir la méthode de sélection des utilisateurs à traiter : à partir d'un fichier CSV (choix 1) ou d'une OU (choix 2)
#  -Renseigner le chemin du fichier CSV ou l'OU contenant les utilisateurs à traiter
#   Note : vous pouvez récupérer le DN d'une OU à partie de l'éditeur d'attributs dans la console Utilisateurs & Ordinateurs AD
#  -Le traitement s'effectue et le script affiche à l'écran le détail pour chaque utilisateur
#  -Un rapport est généré à l'emplacement $cheminRapport
########################################################################
Add-Type –AssemblyName System.Windows.Forms
#Définition des variables
$cheminRapport = 'C:\Scripts\Changement UPN - OneDrive\RapportChgmtUPN.csv'
$excludeList = 'C:\Scripts\Changement UPN - OneDrive\ExcludeList.csv'
Write-Host "#### Script de modification des UPN ####"
Write-Host "########################################"
Write-Host ""
Write-Host "Méthode 1: Sélectionner les utilisateurs à partir d'un fichier CSV"
Write-Host "Méthode 2: Sélectionner les utilisateurs à partir d'une OU"
Write-Host "Entrer" -NoNewline
Write-Host " 1 " -ForegroundColor Yellow -NoNewline
Write-Host "ou" -NoNewline
Write-Host " 2 " -ForegroundColor Yellow -NoNewline
Write-Host "pour choisir la méthode de sélection: " -NoNewline
$choix = Read-Host

if ($choix -eq '1') {
	$csv = Read-Host "Entrez le chemin complet du fichier CSV"
	
# Recupération du nombre d'utilisateur pour afficher un message de confirmation
[int]$NbUserATraiter = 0
$reader = New-Object IO.StreamReader $csv
 while($reader.ReadLine() -ne $null){ $NbUserATraiter++ }
 $NbUserATraiter -= 1

$CONFIRMATION= [System.Windows.Forms.MessageBox]::Show("Voulez vous vraiment traiter $NbUserATraiter utilisateurs ?"  , "Confirmation" , 4) 
if ($CONFIRMATION -eq "YES" ) 
{

#	Pour générer un rapport des UPNs modifiés
	$report = @()
	
#	Import du CSV pour traitement des utilisateurs
	Import-Csv -Path $csv | foreach { $SamAccountName = $_.SamAccountName
		$user = Get-ADUser $SamAccountName
		
		$GivenName = $user.GivenName
		$Surname = $user.Surname
		$SamAccountName = $user.SamAccountName
		$UserPrincipalName = $user.UserPrincipalName
		
		$UPN = $GivenName + "." + $Surname + '@example.com'

		$UPN = $UPN -replace 'à', 'a' `
			      -replace 'ä', 'a' `
			      -replace 'ã', 'a' `
			      -replace 'â', 'a' `
				  -replace 'ç', 'c' `
			      -replace 'é', 'e' `
			      -replace 'è', 'e' `
				  -replace 'ë', 'e' `
				  -replace 'ê', 'e' `
				  -replace 'ï', 'i' `
			      -replace 'ö', 'o' `
			      -replace 'õ', 'o' `
			      -replace 'ô', 'o' `
				  -replace 'û', 'u' `
				  -replace 'ü', 'u' `
			      -replace 'ñ', 'n' `
			      -replace "'", '' `
				  -replace ' ', '' 

#Vérification si l'utilisateur doit être traité ; par défaut OUI
		$UserATraiter = $true
#Raison du non traitement d'un utilisateur ; par défaut OK
		$NomRaison= "OK"		
		#On vérifie s'il ne fait pas partie des utilisateurs à exclure
		if (Get-Content $excludeList | Select-String -Pattern $SamAccountName) {
			$UserATraiter = $false
			$NomRaison="Utilisateur exclus"
			Write-Host "L'utilisateur $SamAccountName fait partie des utilisateurs exclus!" 
			}
		
		#On vérifie si l'utilisateur est activé
		$userEnabled = Get-ADUser $SamAccountName -properties Enabled | select Enabled -ExpandProperty Enabled
		if ($userEnabled) {} else {
			$UserATraiter = $false
			$NomRaison="Compte desactive"
			Write-Host "L'utilisateur $SamAccountName est désactivé!"
			}
		
		#On vérifie si l'utilisateur possède une adresse mail
		$u = Get-ADUser $SamAccountName -properties EmailAddress
		if ($u.EmailAddress -like '') {
			$UserATraiter = $false
			$NomRaison="Pas d'email"
			Write-Host "L'utilisateur $SamAccountName n'a pas d'adresse mail!"
			}
			
		#On vérifie si l'utilisateur possède un prénom
		$u = Get-ADUser $SamAccountName -properties GivenName
		if ($u.givenName -like '') {
			$UserATraiter = $false
			$NomRaison="Pas de prénom"
			Write-Host "L'utilisateur $SamAccountName n'a pas de prénom!"
			}
		
		#Si tout est bon, on traite l'utilisateur
		if ($UserAtraiter) {
			Get-ADUser $SamAccountName | Set-ADUser -UserPrincipalName $UPN
			Write-Host "Utilisateur traité: $SamAccountName"
		}
		#		Pour générer un rapport des UPNs modifiés
		$report += New-Object psobject -Property @{GivenName=$GivenName;Surname=$Surname;UPN=$UserPrincipalName;NewUPN=$UPN;SamAccountName=$SamAccountName;Modified=$UserAtraiter}

	}
#	Pour générer un rapport des UPNs modifiés
	$report | export-csv -Path $cheminRapport -Encoding Unicode -NoTypeInformation
	write-host $result
} 
else 
{ 
Write-Host "Bye Bye"
Read-Host -Prompt "Appuyez sur Entrée pour sortir"
exit

}	
}

if ($choix -eq '2') {
	$ou = Read-Host "Entrez le DistinguishedName de l'OU"
# Recupération du nombre d'utilisateur pour afficher un message de confirmation
$NbUserATraiter = Get-ADUser -searchBase $ou -Filter * | measure | Select -ExpandProperty Count

$CONFIRMATION= [System.Windows.Forms.MessageBox]::Show("Voulez vous vraiment traiter $NbUserATraiter utilisateurs ?"  , "Confirmation" , 4) 
if ($CONFIRMATION -eq "YES" ) 
{
#	Pour générer un rapport des UPNs modifiés
	$report = @()

#Récupération des utilisateurs contenus dans l'OU
	Get-ADUser -searchBase $ou -Properties GivenName,Surname,Name,SamAccountName,UserPrincipalName -filter * | foreach { 
		$GivenName = $_.GivenName
		$Surname = $_.Surname
		$SamAccountName = $_.SamAccountName
		$UserPrincipalName = $_.UserPrincipalName
		
		$UPN = $GivenName + "." + $Surname + '@example.com'
		
		$UPN = $UPN -replace 'à', 'a' `
			      -replace 'ä', 'a' `
			      -replace 'ã', 'a' `
			      -replace 'â', 'a' `
				  -replace 'ç', 'c' `
			      -replace 'é', 'e' `
			      -replace 'è', 'e' `
				  -replace 'ë', 'e' `
				  -replace 'ê', 'e' `
				  -replace 'ï', 'i' `
			      -replace 'ö', 'o' `
			      -replace 'õ', 'o' `
			      -replace 'ô', 'o' `
				  -replace 'û', 'u' `
				  -replace 'ü', 'u' `
			      -replace 'ñ', 'n' `
			      -replace "'", '' `
				  -replace ' ', ''
		
#Vérification si l'utilisateur doit être traité ; par défaut OUI
		$UserATraiter = $true
#Raison du non traitement d'un utilisateur ; par défaut OK
		$NomRaison= "OK"
		#On vérifie s'il ne fait pas partie des utilisateurs à exclure
		if (Get-Content $excludeList | Select-String -Pattern $SamAccountName) {
			$UserATraiter = $false
			$NomRaison="Utilisateur exclus"
			Write-Host "L'utilisateur $SamAccountName fait partie des utilisateurs exclus!" 
			}
		
		#On vérifie si l'utilisateur est activé
		$userEnabled = Get-ADUser $SamAccountName -properties Enabled | select Enabled -ExpandProperty Enabled
		if ($userEnabled) {} else {
			$UserATraiter = $false
			$NomRaison="Compte desactive"
			Write-Host "L'utilisateur $SamAccountName est désactivé!"
			}
		
		#On vérifie si l'utilisateur possède une adresse mail
		$u = Get-ADUser $SamAccountName -properties EmailAddress
		if ($u.EmailAddress -like '') {
			$UserATraiter = $false
			$NomRaison="Pas d'email"
			Write-Host "L'utilisateur $SamAccountName n'a pas d'adresse mail!"
			}
		
		#On vérifie si l'utilisateur possède un prénom
		$u = Get-ADUser $SamAccountName -properties GivenName
		if ($u.givenName -like '') {
			$UserATraiter = $false
			$NomRaison="Pas de prénom"
			Write-Host "L'utilisateur $SamAccountName n'a pas de prénom!"
			}
			
		#Si tout est bon, on traite l'utilisateur
		if ($UserAtraiter) {
			Get-ADUser $SamAccountName | Set-ADUser -UserPrincipalName $UPN
			Write-Host "Utilisateur traité: $SamAccountName"
		}
		#	Pour générer un rapport des UPNs modifiés
		$report += New-Object psobject -Property @{GivenName=$GivenName;Surname=$Surname;OldUPN=$UserPrincipalName;NewUPN=$UPN;SamAccountName=$SamAccountName;Modified=$UserAtraiter;Raison=$NomRaison}

	}	
#	Pour générer un rapport des UPNs modifiés
	$report | export-csv -Path $cheminRapport -Encoding Unicode -NoTypeInformation
} 
else 
{ 
Write-Host "Bye Bye"
Read-Host -Prompt "Appuyez sur Entrer pour sortir"
exit

}	
}
Read-Host -Prompt "Appuyez sur Entrer pour sortir"