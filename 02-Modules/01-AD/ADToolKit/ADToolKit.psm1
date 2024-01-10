#Requires -Version 5.0
using namespace System.Management.Automation

function Sync-DomainController {
	<#
	.SYNOPSIS
	Force AD replication between DC.
	.DESCRIPTION
	Force sync using repadmin
	.EXAMPLE
	Sync-DomainController
#>
    [CmdletBinding()]
    param(
        [string] $Domain = $Env:USERDNSDOMAIN,
		[switch]$Verbose = $true
    )
    $DistinguishedName = (Get-ADDomain -Server $Domain).DistinguishedName
    (Get-ADDomainController -Filter * -Server $Domain).Name | ForEach-Object {
        Write-Verbose -Message "Sync-DomainController - Forcing synchronization $_"
        repadmin /syncall $_ $DistinguishedName /e /A | Out-Null
    }
}

function Redo-KccTopology {
	[CmdletBinding()]
    param(
		[switch]$Verbose = $true
    )
	$AllDC = (Get-ADForest).Domains | %{ Get-ADDomainController -Filter *}
	
	$AllDC | ForEach-Object {
        Write-Verbose -Message "Redo-KccTopology - Forcing KCC to verify the topology $_"
        repadmin /kcc $_.Hostname | Out-Null
    }
}

function  Get-DistinguishedName {
	<#
		.SYNOPSIS
		Get the Distinguished Name from a Canonical Name.
		https://millerb.co.uk/2019/07/16/Get-DistinguishedName-From-CanonicalName.html
		.DESCRIPTION
		Get the Distinguished Name from a Canonical Name.
		.EXAMPLE
		Get-DistinguishedName -CanonicalName @(
			'MyDomain.co.uk/Corp/Users/User2 Test'
			'OtherDomain.com/Corp/Users/User2 Test'
			'sub.domain.org.co.uk/Corp/Users/User2 Test'
			'sub.sub.domain.org/Corp/Users/User2 Test'
		)

		@(
			'MyDomain.co.uk/Corp/Users/User2 Test'
			'OtherDomain.com/Corp/Users/User2 Test'
			'sub.domain.org.co.uk/Corp/Users/User2 Test'
			'sub.sub.domain.org/Corp/Users/User2 Test'
		) | Get-DistinguishedName
	#>
    param (
        [Parameter(Mandatory,
        ParameterSetName = 'Input')]
        [string[]]
        $CanonicalName,

        [Parameter(Mandatory,
            ValueFromPipeline,
            ParameterSetName = 'Pipeline')]
        [string]
        $InputObject
    )
    process {
        if ($PSCmdlet.ParameterSetName -eq 'Pipeline') {
            $arr = $_ -split '/'
            [array]::reverse($arr)
            $output = @()
            $output += $arr[0] -replace '^.*$', 'CN=$0'
            $output += ($arr | select -Skip 1 | select -SkipLast 1) -replace '^.*$', 'OU=$0'
            $output += ($arr | ? { $_ -like '*.*' }) -split '\.' -replace '^.*$', 'DC=$0'
            $output -join ','
        }
        else {
            foreach ($cn in $CanonicalName) {
                $arr = $cn -split '/'
                [array]::reverse($arr)
                $output = @()
                $output += $arr[0] -replace '^.*$', 'CN=$0'
                $output += ($arr | select -Skip 1 | select -SkipLast 1) -replace '^.*$', 'OU=$0'
                $output += ($arr | ? { $_ -like '*.*' }) -split '\.' -replace '^.*$', 'DC=$0'
                $output -join ','
            }
        }
    }
}

function Split-DN {
	<#
		.SYNOPSIS
		Get each part (CN/OU/DC) of a Distinguished Name
		https://stackoverflow.com/questions/67502781/get-cn-value-from-aduser-distinguishedname
		.DESCRIPTION
		Get each part (CN/OU/DC) of a Distinguished Name.
		Avantage over a simple regex is that the function can handle specific escaped characters that might appears in a DN but not via the GUI.
		- Handles escaped, embedded , chars., as well as other escape sequences, correctly
		- Unescapes the values, which includes not just removing syntactic \, but also converting escape sequences in the form \<hh>, where hh is a two-digit hex. number representing a character's code point, to the actual character they represent (e.g, \3C, is converted to a < character).
		- Outputs an ordered hashtable whose keys are the name components (e.g., CN, OU), with the values for names that occur multiple times - such as OU - represented as an array
		.EXAMPLE
		Split-DN "CN=Generic,OU=CHB,OU=FR,OU=ACOGR,OU=ACOEM_Users,DC=acoem,DC=local"

		Output:
		Name                           Value
		----                           -----
		CN                             Generic
		OU                             {CHB, FR, ACOGR, ACOEM_Users}
		DC                             {acoem, local}
	#>
  param(
    [Parameter(Mandatory)]
    [string] $DN
  )

  # Initialize the (ordered) output hashtable.
  $oht = [ordered] @{}

  # Split into name-value pairs, while correctly recognizing escaped, embedded
  # commas.
  $nameValuePairs = $DN -split '(?<=(?:^|[^\\])(?:\\\\)*),'

  $nameValuePairs.ForEach({

    # Split into name and value.
    # Note: Names aren't permitted to contain escaped chars.
    $name, $value = ($_ -split '=', 2).Trim()

    # Unescape the value, if necessary.
    if ($value -and $value.Contains('\')) {
      $value = [regex]::Replace($value, '(?i)\\(?:[0-9a-f]){2}|\\.', {
        $char = $args[0].ToString().Substring(1)
        if ($char.Length -eq 1) { # A \<literal-char> sequence.
          $char # Output the character itself, without the preceding "\"
        }
        else { # A \<hh> escape sequence, conver the hex. code point to a char.
          [char] [uint16]::Parse($char, 'AllowHexSpecifier') 
        }
      })
    }
    
    # Add an entry to the output hashtable. If one already exists for the name,
    # convert the existing value to an array, if necessary, and append the new value.
    if ($existingEntry = $oht[$name]) {
      $oht[$name] = ([array] $existingEntry) + $value
    }
    else {
      $oht[$name] = $value
    }

  })

  # Output the hashtable.
  $oht
}

#Updated ConvertFrom-DN to support container objects

function ConvertFrom-DN {
	# https://gist.github.com/joegasper/3fafa5750261d96d5e6edf112414ae18
    [cmdletbinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [ValidateNotNullOrEmpty()]
        [string[]]$DistinguishedName
    )
    process {
        foreach ($DN in $DistinguishedName) {
            Write-Verbose $DN
            $CanonNameSlug = ''
            $DC = ''
            foreach ( $item in ($DN.replace('\,', '~').split(','))) {
                if ( $item -notmatch 'DC=') {
                    $CanonNameSlug = $item.Substring(3) + '/' + $CanonNameSlug
                }
                else {
                    $DC += $item.Replace('DC=', ''); $DC += '.'
                }
            }
            $CanonicalName = $DC.Trim('.') + '/' + $CanonNameSlug.Replace('~', '\,').Trim('/')
            [PSCustomObject]@{
                'CanonicalName' = $CanonicalName;
            }
        }
    }
}

function ConvertFrom-CanonicalUser {
	# https://gist.github.com/joegasper/3fafa5750261d96d5e6edf112414ae18
    [cmdletbinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$CanonicalName
    )
    process {
        $obj = $CanonicalName.Split('/')
        [string]$DN = 'CN=' + $obj[$obj.count - 1]
        for ($i = $obj.count - 2; $i -ge 1; $i--) { $DN += ',OU=' + $obj[$i] }
        $obj[0].split('.') | ForEach-Object { $DN += ',DC=' + $_ }
        return $DN
    }
}

function ConvertFrom-CanonicalOU {
	# https://gist.github.com/joegasper/3fafa5750261d96d5e6edf112414ae18
    [cmdletbinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$CanonicalName
    )
    process {
        $obj = $CanonicalName.Split('/')
        [string]$DN = 'OU=' + $obj[$obj.count - 1]
        for ($i = $obj.count - 2; $i -ge 1; $i--) { $DN += ',OU=' + $obj[$i] }
        $obj[0].split('.') | ForEach-Object { $DN += ',DC=' + $_ }
        return $DN
    }
}