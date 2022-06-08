<#
.NOTES
    Author: Nick Eales, Microsoft
    Adapted by Adrien LERAYER
    a.lerayer@ava6.fr
    https://randomitdude.com
    https://ava6.fr

.Synopsis 
   Sample script to decline superseded updates from WSUS, and run WSUS cleanup if any changes are made  

.DESCRIPTION 
   Declines updates from WSUS if update meets any of the following:
        - is superseded
        - is expired (as defined by Microsoft)
        - is for x86 or itanium operating systems
        - is for Windows XP
        - is a language pack
        - is for old versions of Internet Explorer (versions 7,8,9)
        - contains some country names for country specific updates not filtered by WSUS language filters.
        - is a beta update
        - is for an embedded operating system

    If an update is released for multiple operating systems, and one or more of the above criteria are met, the versions of the update that do not meet the above will not be declined by this script

    Change Log (YYYY/MM/DD)
        V1.00, 2016/07/13 - Nick Eales - Initial version
        V1.01, 2022/06/06 - Adrien LERAYER - Added multiple new versions. Changed alias by their full Cmdlet
.EXAMPLE 
   .\Decline-Updates -WSUSServer WSUSServer.Company.com -WSUSPort 8531 -UseSSL

#>


Param(    
    [Parameter(Mandatory=$false, 
    ValueFromPipeline=$true, 
    ValueFromPipelineByPropertyName=$true, 
    ValueFromRemainingArguments=$false, 
    Position=0)] 
    [string]$WSUSServer = "Localhost", #default to localhost
    [int]$WSUSPort=8530,
    [switch]$reportonly,
	[Parameter(Mandatory=$False)]
    [switch] $UseSSL
    )

Function Decline-Updates{
    Param(
        [string]$WsusServer,
        [int]$WSUSPort,
        [switch]$ReportOnly
    )
    write-host "Connecting to WSUS Server $WSUSServer and getting list of updates"
	
    #$Wsus = Get-WSUSserver -Name $WSUSServer -PortNumber $WSUSPort
	try {
		if ($UseSSL) {
			Write-Host "Connecting to WSUS server $UpdateServer on Port $WSUSPort using SSL... " -NoNewLine
			$Wsus = Get-WSUSserver -Name $WSUSServer -PortNumber $WSUSPort -UseSSL
		} Else {
			Write-Host "Connecting to WSUS server $UpdateServer on Port $Port... " -NoNewLine
			$Wsus = Get-WSUSserver -Name $WSUSServer -PortNumber $WSUSPort
		}
		
		[reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | out-null
		#$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($UpdateServer, $UseSSL, $Port);
		#$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer();
	}
	catch [System.Exception] 
	{
		Write-Host "Failed to connect."
		Write-Host "Error:" $_.Exception.Message
		Write-Host "Please make sure that WSUS Admin Console is installed on this machine"
		Write-Host ""
		$wsus = $null
	}

	if ($wsus -eq $null) { return } 

	Write-Host "Connected."
	
    if($WSUS -eq $Null){
        write-error "unable to contact WSUSServer $WSUSServer"
    }else{
        $Updates = $wsus.GetUpdates()
        write-host "$(($Updates | Where-Object {$_.IsDeclined -eq $false} | Measure-Object).Count) Updates before cleanup"
        $updatesToDecline = $updates | Where-Object {$_.IsDeclined -eq $false -and (
        $_.IsSuperseded -eq $true -or   				#remove superseded updates
        $_.PublicationState -eq "Expired" -or 			#remove updates that have been pulled by Microsoft
        $_.LegacyName -match "ia64" -or 				#remove updates for itanium computers (1/2)
        #$_.LegacyName -match "x86" -or                 #remove updates for 32-bit computers
        $_.LegacyName -match "XP" -or                   #remove Windows XP updates (1/2)
        $_.producttitles -match "XP" -or                #remove Windows XP updates (1/2)
        $_.Title -match "Itanium" -or                   #remove updates for itanium computers (2/2)
        $_.Title -match "language\s" -or                #remove language packs
        $_.title -match "Internet Explorer 7" -or       #remove updates for old versions of IE
        $_.title -match "Internet Explorer 8" -or 
        #$_.title -match "Internet Explorer 9" -or 
        $_.title -match "Japanese" -or                  #some non-english updates are not filtered by WSUS language filtering
        $_.title -match "Korean" -or   
        $_.title -match "Taiwan" -or  
        $_.title -match "fr-ca" -or                     # Canadian French
        $_.title -match "en-gb" -or                     # British English
        $_.Title -match "Beta" -or                      #Beta products and beta updates
        $_.title -match "Embedded" -or                  #Embedded version of Windows
		$_.title -match "ARM64" -or
		$_.title -match "Enterprise N" -or              #Enterprise N Edition
		$_.title -clike "*Entreprise*N*" -or            #Enterprise N Edition, French version
		$_.title -match "ducation" -or                  #W10 Education. E is missing for the French version to be included (accent)
		$_.title -match "(consumer editions)" -or       #W10/W11 (consumer editions)
		$_.title -match "consommateur" -or              #W10/W11 (consumer editions), French version. "Affaires" also exists for W11
		$_.title -match "ditions client" -or            #W10/W11 (consumer editions), French version n2. Le E de edition est volontairement retire pour eviter de mettre l'accent
		$_.title -match "Windows 10 Team" -or           #For Windows Surface Hub
		$_.title -like "*Windows*10*Collaboration*" -or  #For Windows Surface Hub, French version
		$_.title -match "Insider" -or                   #For Windows Insider
		$_.title -match "Retail" -or                    #For Retail
		$_.title -like "*Vente au d*tail*" -or          #For Retail, French version
		$_.title -match "Windows 10 Pro N" -or          #For Windows Pro N
		$_.title -clike "*Professionnel*N*" -or         #For Windows Pro N, French version n2
		$_.title -like "*7*8.1*" -or                    #For upgrade packages to W10/W11 (Windows 7 and 8.1 upgrade to). English & French versions
		$_.title -like "Mise * niveau de Windows7*" -or #For upgrade packages to W10/W11, French version, other typo
		$_.title -like "*Windows*10*en-us*" -or         # For W10 upgrades in english
		$_.title -like "*Windows*11*en-us*" -or         # For W11 upgrades in english
		$_.title -like "*Windows*10*Volume" -or         # Old name for Business Edition, W10 v1511 only. Does not affect more recent versions as they have "Business" in their name. Affects Pro and Enterprise versions
		$_.title -like "Upgrade to WIndows 11*" -or     # All upgrades to Windows 11, any edition 
		$_.title -like "Mise * jour vers Windows 11*affaires*" # All upgrades to Windows 11, any edition, french version (edition affaires)
        )}
        
        write-host "$(($updatesToDecline | Measure-Object).Count) Updates to decline"
        $changemade = $false        
        if($reportonly){
            write-host "ReportOnly was set to true, so not making any changes"
        }else{
            $changemade = $true
            $updatesToDecline | ForEach-Object{$_.Decline()}
        }

        #Decline updates released more then 3 months prior to the release of an included service pack
        # - service packs updates don't appear to contain the supersedance information.
        Foreach($SP in $($updates | Where-Object title -match "^Windows Server \d{4} .* Service Pack \d")){
            if(($SP.ProductTitles |Measure-Object ).count -eq 1){
                $updatesToDecline = $updates | Where-Object {$_.IsDeclined -eq $false -and $_.ProductTitles -contains $SP.ProductTitles -and $_.CreationDate -lt $SP.CreationDate.Addmonths(-3)}
                if($updatesToDecline -ne $null){
                    write-host "$(($updatesToDecline | Measure-Object).Count) Updates to decline (superseded by $($SP.Title))"
                    if(-not $reportonly){
                        $changemade = $true
                        $updatesToDecline | ForEach-Object{$_.Decline()}
                    }
                }
            }
        }
        
        #if changes were made, run a WSUS cleanup to recover disk space
        if($changemade -eq $true -and $reportonly -eq $false){
            $Updates = $wsus.GetUpdates()
            write-host "$(($Updates | Where-Object {$_.IsDeclined -eq $false} | Measure-Object).Count) Updates remaining, running WSUS cleanup"
            Invoke-WsusServerCleanup -updateServer $WSUS -CleanupObsoleteComputers -CleanupUnneededContentFiles -CleanupObsoleteUpdates -CompressUpdates -DeclineExpiredUpdates -DeclineSupersededUpdates
        }

    }
}

Decline-Updates -WSUSServer $WSUSServer -WSUSPort $WSUSPort -reportonly:$reportonly