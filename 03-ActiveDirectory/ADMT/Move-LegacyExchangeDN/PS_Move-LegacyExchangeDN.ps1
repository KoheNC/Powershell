###########################################################################################################################################
# AVA6 SERVICES
# Adrien LERAYER
# 07/09/2020
#
# SUJET : Migrate LegacyExchangeDN from CSV into the target forest
###########################################################################################################################################
# Compteurs / Execution path
$i = 0
$iProcessed = 0
$iExcluded = 0
$Scriptpath = Split-Path $MyInvocation.MyCommand.Path

# Where is the CSV located
$CsvInput = $Scriptpath + "\LegacyExchangeDN-To-Migrate.csv"
$CsvInputTemp = Get-Content $CsvInput
$CsvInputTemp | Set-Content -Path $CsvInput -Encoding Unicode

Import-Csv -Delimiter ';' -Path $CsvInput -Encoding Unicode | `
    ForEach-Object{
        $ExDNSource = $_.LegacyExchangeDN
        $SAM        = $_.SamAccountName
        $i++

        if($ExDNSource -ne "#N/A")
        {
            #Set-ADuser $SAM -Replace @{legacyExchangeDN=$ExDNSource}
            Set-ADGroup $SAM -Replace @{legacyExchangeDN=$ExDNSource}
            $iProcessed++
            Write-Host $i" - Processing "$SAM -ForegroundColor Green
        }
        else {
            $iExcluded++
        }
    }
Write-Host "Nombre objets traites = "$i -ForegroundColor Yellow
Write-Host "      dont nombre objets acceptes = "$iProcessed -ForegroundColor Green
Write-Host "      dont nombre objets ignores = "$iExcluded -ForegroundColor Red