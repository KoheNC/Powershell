Function blabla
{
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory=$false,Position=1)][String]$OU="OU=GGUsers,DC=G-G,DC=FR"
	)
	Process
	{
		try{
			return ,$Companies
		 }
			Catch
			{
			}
	}
}

#The difference is that module was written by folks who don't handle errors correctly, so it doesn't respect the error preferences it supposedly supports. Similar issues in portions of the AD modules.

#The only good way to work with that where you need to catch the error is to use the global ErrorActionPreference variable -- but you have to put it back how you found it when you're done.

try {
    $OldPref = $global:ErrorActionPreference
    $global:ErrorActionPreference = 'Stop'
    Get-Mailbox "bogus.user"
}
catch {
    Write-Host "It was caught"
}
finally {
    $global:ErrorActionPreference = $OldPref
}


# Script execution path
$directoryPath = Split-Path $MyInvocation.MyCommand.Path

<#
	return $list
	causes the collection to unravel and get "piped" out one by one. Such is the nature of PowerShell.

	You can prevent this, by wrapping the output variable itself in a 1-item array, using the unary array operator ,:

	return ,$list
	OR return @(,$list)

-----

	The only reason your ArrayList example returns object[] is that ArrayList's Add() method returns a value (the old element count), which pollutes the function's output stream and thus returns a regular PS array (object[]), whose last element is the ArrayList. If you use a generic type (e.g., System.Collections.Generic.List[string]), you'll see that Mathias's claim is correct (alternatively, use $null = $list.Add(...)). – mklement0 Jul 8 '16 at 3:16 
#>
$QuoteList = New-Object 'System.Collections.Generic.List[psobject]'
$aduserSociete = [System.Collections.ArrayList]@()
$Hashtable = @{}

$Properties = [ordered]@{
					Country			= $user.c
					HouseIdentifier	= $user.HouseIdentifier
					Nom 			= $user.Surname
					Prenom 			= $user.GivenName
				}
$results += New-Object PSObject -Property $Properties
$Results | Export-csv -Path $DestinationFile -NoTypeInformation -delimiter ";" -Encoding UTF8
(gc $DestinationFile) | % {$_ -replace '"', ""} | out-file $DestinationFile -Force -Encoding UTF8

# Does AD module was previously loaded? # If not, let's do it
If (!(Get-Module "ActiveDirectory")){
	Import-Module "ActiveDirectory" -ErrorAction SilentlyContinue
	
	# Check everything went fine. If there was an error, report it and stop the script.
	If (!$?)
	{
		Write-Host -ForegroundColor Red "Il y a eu une erreur en chargeant le module ActiveDirectory. Le script va se terminer maintenant..."
		BREAK
	}
}

$Hashed = $Hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($QuoteList[$i]))
[String]$HashString = [BitConverter]::ToString($Hashed).Replace('-', $Null)
            
# If the offline quote file doesn't exist, create it
If (-Not(Test-Path (Join-Path (Join-Path $Env:LOCALAPPDATA 'Get-Quotation') $HashString) -PathType Leaf))
{           
	$QuoteList[$i] | Out-File (Join-Path (Join-Path $Env:LOCALAPPDATA 'Get-Quotation') $HashString)
}