###########################################################################################################################################
# AVASSYS
# Adrien LERAYER
# 12/05/2016
#
# SUJET : Lancement de la migration des BAL s depuis le domaine XXX vers le domaine YYY
# ATTENTION : La preparation des BAL (Prepare-MoveRequest) et l'ADMT doivent avoir ete effectues AVANT !!!
# Les Move-Request sont avec l'option -SuspendWhenReadyToComplete qui ne commit pas la BAL une fois la migration effectuee. Le deplacement est OK lorsque le deplacement est à 95%
###########################################################################################################################################
# Only for Exch2010
#Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010;

# Compteur / Execution path
$i = 0
$Scriptpath = Split-Path $MyInvocation.MyCommand.Path

# Where is the CSV located
$CsvInput = $Scriptpath + "\Mbx-To-Migrate.csv"

Set-location "$env:ExchangeInstallPath\Scripts"

# Connexion au domaine source
$SourceUsername     = "LM2K\audit"
$SourcePwd          = Get-Content C:\00-Sources\Migrate-Mailbox\LM2K_PASSWORD.txt | ConvertTo-SecureString
$SourceCredentials  = New-Object -typename System.Management.Automation.PSCredential -argumentlist $SourceUsername, $SourcePwd
$RemoteExchange     = "HERMES.lm2k.fr"

# Fichier contenant les BAL qui doivent etre preparees. L'entete doit avoir le nom "identity" et contenir les adresses emails des utilisateurs et la DB cible
Import-Csv -Path $CsvInput |
    ForEach-Object {
        $identity               = $_.identity
        $TargetDB               = $_.TargetDB
        $TargetDeliveryDomain   = $identity.split('@')[1]
        
        New-MoveRequest -Identity $identity `
            -Remotehostname $RemoteExchange `
            –TargetDatabase $TargetDB `
            -RemoteCredential $SourceCredentials `
            -TargetDeliverydomain $TargetDeliveryDomain `
            -SuspendWhenReadyToComplete `
            -Remote 
        $i++
    }
Write-Host "Nombre objets traites = "$i -ForegroundColor Green
Set-location $Scriptpath