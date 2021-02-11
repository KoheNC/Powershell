###########################################################################################################################################
# AVA6 SERVICES
# Adrien LERAYER
# 07/09/2020
#
# SUJET : Remove "user must change their password option" & Set "users cannot change password" option 
###########################################################################################################################################
# Compteurs / Execution path
$i = 0
$Scriptpath = Split-Path $MyInvocation.MyCommand.Path

# Where is the CSV located
$CsvInput = $Scriptpath + "\SANTE-Users.csv"
$ContentTemp = Get-Content $CsvInput 
$ContentTemp | Set-Content -Path $CsvInput -Encoding Unicode

Import-Module activedirectory
Import-Csv -Path $CsvInput -Delimiter ";" | `
	ForEach-Object{
		$SAM = $_.SamAccountName
		Get-ADUser -identity $SAM | Set-ADUser -CannotChangePassword:$true -ChangePasswordAtLogon:$false -PasswordNeverExpires:$True
		$i++
}
Write-Host "Nombre objets traites = "$i -ForegroundColor Green
