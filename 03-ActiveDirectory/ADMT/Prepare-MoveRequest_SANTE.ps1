###########################################################################################################################################
# AV6 SERVICES
# Adrien LERAYER
# 25/08/2020
#
# SUJET : Preparation des BAL qui seront migrées depuis le domaine source XXX vers le domaine cible YYY
# Note : La preparation des BAL doit etre effectuee AVANT l'ADMT !!!
###########################################################################################################################################
# Only for Exch2010
# Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010;"

# Compteur / Execution path
$i = 0
$Scriptpath = Split-Path $MyInvocation.MyCommand.Path

# Define the OU where users will be created
$TargetMailOU = "OU=USERS,OU=ADMT-Migration,DC=sante,DC=lan"

# Where is the CSV located
$CsvInput = $Scriptpath + "\Mbx-To-Migrate.csv"

Set-location "$env:ExchangeInstallPath\Scripts"

# Connexion au domaine source
$SourceUsername     = "LM2K\audit"
$SourcePwd          = Get-Content C:\00-Sources\Migrate-Mailbox\LM2K_PASSWORD.txt | ConvertTo-SecureString
$SourceCredentials  = New-Object -typename System.Management.Automation.PSCredential -argumentlist $SourceUsername, $SourcePwd
$SourceDC           = "DC1.lm2k.fr"

# Connexion au domaine cible
$TargetUsername     = "SANTE\adm.ava.lerayer"
$TargetPwd          = Get-Content C:\00-Sources\Migrate-Mailbox\SANTE_PASSWORD.txt | ConvertTo-SecureString
$TargetCredentials  = New-Object -typename System.Management.Automation.PSCredential -argumentlist $TargetUsername, $TargetPwd
$TargetDC           = "CBS-DC01.sante.lan"

# Fichier contenant les BAL qui doivent etre preparees. L'entete doit avoir le nom "identity" et contenir les adresses emails des utilisateurs
Import-Csv -Path $CsvInput |
        ForEach-Object {
            .\Prepare-MoveRequest.Ps1 `
                -Identity $_.identity `
                -RemoteForestDomainController $SourceDC `
                -RemoteForestCredential $SourceCredentials `
                -LocalForestDomainController $TargetDC `
                -LocalForestCredential $TargetCredentials `
                -TargetMailUserOU $TargetMailOU `
                -UseLocalObject `
                –Verbose
            $i++
        }

Write-Host "Nombre objets traites = "$i -ForegroundColor Green

Set-location $Scriptpath

