#######################################################################
#Script de changement d'UPN en prenom.nom@example.com
#
# 18/07/2016 - Mathieu CROZIER - AVA6
#
#Fonctionnement du script:
#  -Lancer le script depuis une invite de commande Powershell : C:\Scripts\Changement UPN - OneDrive\ChangeUsersUPN.ps1
#  -Choisir la m�thode de s�lection des utilisateurs � traiter : � partir d'un fichier CSV (choix 1) ou d'une OU (choix 2)
#  -Renseigner le chemin du fichier CSV ou l'OU contenant les utilisateurs � traiter
#   Note : vous pouvez r�cup�rer le DN d'une OU � partie de l'�diteur d'attributs dans la console Utilisateurs & Ordinateurs AD
#  -Le traitement s'effectue et le script affiche � l'�cran le d�tail pour chaque utilisateur
#  -Un rapport est g�n�r� � l'emplacement $cheminRapport
########################################################################
Add-Type �AssemblyName System.Windows.Forms
#D�finition des variables
$cheminRapport = 'C:\Scripts\Changement UPN - OneDrive\RapportChgmtUPN.csv'
$excludeList = 'C:\Scripts\Changement UPN - OneDrive\ExcludeList.csv'
Write-Host "#### Script de modification des UPN ####"
Write-Host "########################################"
Write-Host ""
Write-Host "M�thode 1: S�lectionner les utilisateurs � partir d'un fichier CSV"
Write-Host "M�thode 2: S�lectionner les utilisateurs � partir d'une OU"
Write-Host "Entrer" -NoNewline
Write-Host " 1 " -ForegroundColor Yellow -NoNewline
Write-Host "ou" -NoNewline
Write-Host " 2 " -ForegroundColor Yellow -NoNewline
Write-Host "pour choisir la m�thode de s�lection: " -NoNewline
$choix = Read-Host

if ($choix -eq '1') {
	$csv = Read-Host "Entrez le chemin complet du fichier CSV"
	
# Recup�ration du nombre d'utilisateur pour afficher un message de confirmation
[int]$NbUserATraiter = 0
$reader = New-Object IO.StreamReader $csv
 while($reader.ReadLine() -ne $null){ $NbUserATraiter++ }
 $NbUserATraiter -= 1

$CONFIRMATION= [System.Windows.Forms.MessageBox]::Show("Voulez vous vraiment traiter $NbUserATraiter utilisateurs ?"  , "Confirmation" , 4) 
if ($CONFIRMATION -eq "YES" ) 
{

#	Pour g�n�rer un rapport des UPNs modifi�s
	$report = @()
	
#	Import du CSV pour traitement des utilisateurs
	Import-Csv -Path $csv | foreach { $SamAccountName = $_.SamAccountName
		$user = Get-ADUser $SamAccountName
		
		$GivenName = $user.GivenName
		$Surname = $user.Surname
		$SamAccountName = $user.SamAccountName
		$UserPrincipalName = $user.UserPrincipalName
		
		$UPN = $GivenName + "." + $Surname + '@example.com'

		$UPN = $UPN -replace '�', 'a' `
			      -replace '�', 'a' `
			      -replace '�', 'a' `
			      -replace '�', 'a' `
				  -replace '�', 'c' `
			      -replace '�', 'e' `
			      -replace '�', 'e' `
				  -replace '�', 'e' `
				  -replace '�', 'e' `
				  -replace '�', 'i' `
			      -replace '�', 'o' `
			      -replace '�', 'o' `
			      -replace '�', 'o' `
				  -replace '�', 'u' `
				  -replace '�', 'u' `
			      -replace '�', 'n' `
			      -replace "'", '' `
				  -replace ' ', '' 

#V�rification si l'utilisateur doit �tre trait� ; par d�faut OUI
		$UserATraiter = $true
#Raison du non traitement d'un utilisateur ; par d�faut OK
		$NomRaison= "OK"		
		#On v�rifie s'il ne fait pas partie des utilisateurs � exclure
		if (Get-Content $excludeList | Select-String -Pattern $SamAccountName) {
			$UserATraiter = $false
			$NomRaison="Utilisateur exclus"
			Write-Host "L'utilisateur $SamAccountName fait partie des utilisateurs exclus!" 
			}
		
		#On v�rifie si l'utilisateur est activ�
		$userEnabled = Get-ADUser $SamAccountName -properties Enabled | select Enabled -ExpandProperty Enabled
		if ($userEnabled) {} else {
			$UserATraiter = $false
			$NomRaison="Compte desactive"
			Write-Host "L'utilisateur $SamAccountName est d�sactiv�!"
			}
		
		#On v�rifie si l'utilisateur poss�de une adresse mail
		$u = Get-ADUser $SamAccountName -properties EmailAddress
		if ($u.EmailAddress -like '') {
			$UserATraiter = $false
			$NomRaison="Pas d'email"
			Write-Host "L'utilisateur $SamAccountName n'a pas d'adresse mail!"
			}
			
		#On v�rifie si l'utilisateur poss�de un pr�nom
		$u = Get-ADUser $SamAccountName -properties GivenName
		if ($u.givenName -like '') {
			$UserATraiter = $false
			$NomRaison="Pas de pr�nom"
			Write-Host "L'utilisateur $SamAccountName n'a pas de pr�nom!"
			}
		
		#Si tout est bon, on traite l'utilisateur
		if ($UserAtraiter) {
			Get-ADUser $SamAccountName | Set-ADUser -UserPrincipalName $UPN
			Write-Host "Utilisateur trait�: $SamAccountName"
		}
		#		Pour g�n�rer un rapport des UPNs modifi�s
		$report += New-Object psobject -Property @{GivenName=$GivenName;Surname=$Surname;UPN=$UserPrincipalName;NewUPN=$UPN;SamAccountName=$SamAccountName;Modified=$UserAtraiter}

	}
#	Pour g�n�rer un rapport des UPNs modifi�s
	$report | export-csv -Path $cheminRapport -Encoding Unicode -NoTypeInformation
	write-host $result
} 
else 
{ 
Write-Host "Bye Bye"
Read-Host -Prompt "Appuyez sur Entr�e pour sortir"
exit

}	
}

if ($choix -eq '2') {
	$ou = Read-Host "Entrez le DistinguishedName de l'OU"
# Recup�ration du nombre d'utilisateur pour afficher un message de confirmation
$NbUserATraiter = Get-ADUser -searchBase $ou -Filter * | measure | Select -ExpandProperty Count

$CONFIRMATION= [System.Windows.Forms.MessageBox]::Show("Voulez vous vraiment traiter $NbUserATraiter utilisateurs ?"  , "Confirmation" , 4) 
if ($CONFIRMATION -eq "YES" ) 
{
#	Pour g�n�rer un rapport des UPNs modifi�s
	$report = @()

#R�cup�ration des utilisateurs contenus dans l'OU
	Get-ADUser -searchBase $ou -Properties GivenName,Surname,Name,SamAccountName,UserPrincipalName -filter * | foreach { 
		$GivenName = $_.GivenName
		$Surname = $_.Surname
		$SamAccountName = $_.SamAccountName
		$UserPrincipalName = $_.UserPrincipalName
		
		$UPN = $GivenName + "." + $Surname + '@example.com'
		
		$UPN = $UPN -replace '�', 'a' `
			      -replace '�', 'a' `
			      -replace '�', 'a' `
			      -replace '�', 'a' `
				  -replace '�', 'c' `
			      -replace '�', 'e' `
			      -replace '�', 'e' `
				  -replace '�', 'e' `
				  -replace '�', 'e' `
				  -replace '�', 'i' `
			      -replace '�', 'o' `
			      -replace '�', 'o' `
			      -replace '�', 'o' `
				  -replace '�', 'u' `
				  -replace '�', 'u' `
			      -replace '�', 'n' `
			      -replace "'", '' `
				  -replace ' ', ''
		
#V�rification si l'utilisateur doit �tre trait� ; par d�faut OUI
		$UserATraiter = $true
#Raison du non traitement d'un utilisateur ; par d�faut OK
		$NomRaison= "OK"
		#On v�rifie s'il ne fait pas partie des utilisateurs � exclure
		if (Get-Content $excludeList | Select-String -Pattern $SamAccountName) {
			$UserATraiter = $false
			$NomRaison="Utilisateur exclus"
			Write-Host "L'utilisateur $SamAccountName fait partie des utilisateurs exclus!" 
			}
		
		#On v�rifie si l'utilisateur est activ�
		$userEnabled = Get-ADUser $SamAccountName -properties Enabled | select Enabled -ExpandProperty Enabled
		if ($userEnabled) {} else {
			$UserATraiter = $false
			$NomRaison="Compte desactive"
			Write-Host "L'utilisateur $SamAccountName est d�sactiv�!"
			}
		
		#On v�rifie si l'utilisateur poss�de une adresse mail
		$u = Get-ADUser $SamAccountName -properties EmailAddress
		if ($u.EmailAddress -like '') {
			$UserATraiter = $false
			$NomRaison="Pas d'email"
			Write-Host "L'utilisateur $SamAccountName n'a pas d'adresse mail!"
			}
		
		#On v�rifie si l'utilisateur poss�de un pr�nom
		$u = Get-ADUser $SamAccountName -properties GivenName
		if ($u.givenName -like '') {
			$UserATraiter = $false
			$NomRaison="Pas de pr�nom"
			Write-Host "L'utilisateur $SamAccountName n'a pas de pr�nom!"
			}
			
		#Si tout est bon, on traite l'utilisateur
		if ($UserAtraiter) {
			Get-ADUser $SamAccountName | Set-ADUser -UserPrincipalName $UPN
			Write-Host "Utilisateur trait�: $SamAccountName"
		}
		#	Pour g�n�rer un rapport des UPNs modifi�s
		$report += New-Object psobject -Property @{GivenName=$GivenName;Surname=$Surname;OldUPN=$UserPrincipalName;NewUPN=$UPN;SamAccountName=$SamAccountName;Modified=$UserAtraiter;Raison=$NomRaison}

	}	
#	Pour g�n�rer un rapport des UPNs modifi�s
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