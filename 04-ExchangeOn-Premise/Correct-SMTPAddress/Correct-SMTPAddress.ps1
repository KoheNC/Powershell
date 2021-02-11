###########################################################################################################################################
# AVA6 SERVICES
# Adrien LERAYER
# 07/09/2020
#
# SUJET : Remove existing smtp address and set new ones
###########################################################################################################################################
$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

# Compteurs / Execution path
$i = 0
$iProcessed = 0
$iExcluded = 0
$Scriptpath = Split-Path $MyInvocation.MyCommand.Path

# Where is the CSV located
$CsvInput = $Scriptpath + "\SMTP-Address.csv"
$CsvInputTemp = Get-Content $CsvInput
$CsvInputTemp | Set-Content -Path $CsvInput -Encoding UTF8

Import-Csv -Delimiter ';' -Path $CsvInput | `
    ForEach-Object{
        $NewProxyAddresses = $_.proxyaddresses -split ","
        $SAM        = $_.SamAccountName
        $mail       = $_.mail
        $i++

        $user = Get-AdUser $SAM -Properties proxyaddresses,mail

        # Delete actual SMTP Addresses
        foreach($proxyAddress in $user.proxyAddresses){
            if($proxyAddress -like "smtp:*"){
                Set-ADUser -Identity $SAM -Remove @{proxyAddresses=@($proxyAddress)}  
            }
        }

        # Add new SMTP Addresses
        foreach($NewProxyAddress in $NewProxyAddresses){
                Set-ADUser -Identity $SAM -Add @{proxyAddresses=@($NewProxyAddress)}
        }

        # Change UPN & mail
        Set-ADUser $SAM -UserPrincipalName $mail -emailAddress $mail
        
        $iProcessed++
        Write-Host $i" - Adding smtp address for "$SAM -ForegroundColor Green

        # For MEU only
        #Set-ADUser $SAM -Replace @{targetAddress=("SMTP:"+$($mail))}
    }
Write-Host "Nombre objets traites = "$i -ForegroundColor Yellow
Write-Host "      dont nombre objets acceptes = "$iProcessed -ForegroundColor Green
#Write-Host "      dont nombre objets ignores = "$iExcluded -ForegroundColor Red