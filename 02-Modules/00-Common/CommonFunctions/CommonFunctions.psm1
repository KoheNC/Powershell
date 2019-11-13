#Requires -Version 5.0
using namespace System.Management.Automation


Function Write-InformationColored {
<#
    .SYNOPSIS
        Writes messages to the information stream, optionally with
        color when written to the host.
    .DESCRIPTION
        An alternative to Write-Host which will write to the information stream
        and the host (optionally in colors specified) but will honor the
        $InformationPreference of the calling context.
        In PowerShell 5.0+ Write-Host calls through to Write-Information but
        will _always_ treats $InformationPreference as 'Continue', so the caller
        cannot use other options to the preference variable as intended.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Object]$MessageData,
        [ConsoleColor]$ForegroundColor = $Host.UI.RawUI.ForegroundColor, # Make sure we use the current colours by default
        [ConsoleColor]$BackgroundColor = $Host.UI.RawUI.BackgroundColor,
        [Switch]$NoNewline
    )

    $msg = [HostInformationMessage]@{
        Message         = $MessageData
        ForegroundColor = $ForegroundColor
        BackgroundColor = $BackgroundColor
        NoNewline       = $NoNewline.IsPresent
    }

    Write-Information $msg
}

function Remove-StringLatinCharacters
{
<#
.SYNOPSIS
	This function will remove the diacritics (accents) characters from a string.
.DESCRIPTION
	This function will remove the diacritics (accents) characters from a string.
.PARAMETER String
	Specifies the String(s) on which the diacritics need to be removed
.PARAMETER NormalizationForm
	Specifies the normalization form to use
	https://msdn.microsoft.com/en-us/library/system.text.normalizationform(v=vs.110).aspx
.EXAMPLE
	PS C:\> Remove-StringDiacritic "L'été de Raphaël"
	L'ete de Raphael
.NOTES
	Francois-Xavier Cat
	@lazywinadm
	www.lazywinadmin.com
	github.com/lazywinadmin
	
	UPDATE: Thanks to Marcin Krzanowicz who provided another solution, see the Method 2 below. His version works with Polish characters too where the method 1 doesn’t.
#>
# Modify the function to make it compatible with the pipeline

    PARAM (
        [parameter(ValueFromPipeline = $true)]
        [string]$String
    )
    PROCESS
    {
        [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($String))
    }
}

function Remove-StringSpecialCharacter
{
<#
.SYNOPSIS
	This function will remove the special character from a string.
.DESCRIPTION
	This function will remove the special character from a string.
	I'm using Unicode Regular Expressions with the following categories
	\p{L} : any kind of letter from any language.
	\p{Nd} : a digit zero through nine in any script except ideographic 
	http://www.regular-expressions.info/unicode.html
	http://unicode.org/reports/tr18/
.PARAMETER String
	Specifies the String on which the special character will be removed
.SpecialCharacterToKeep
	Specifies the special character to keep in the output
.EXAMPLE
	PS C:\> Remove-StringSpecialCharacter -String "^&*@wow*(&(*&@"
	wow
.EXAMPLE
	PS C:\> Remove-StringSpecialCharacter -String "wow#@!`~)(\|?/}{-_=+*"
	wow
.EXAMPLE
	PS C:\> Remove-StringSpecialCharacter -String "wow#@!`~)(\|?/}{-_=+*" -SpecialCharacterToKeep "*","_","-"
	wow-_*
.NOTES
	Francois-Xavier Cat
	@lazywinadm
	www.lazywinadmin.com
	github.com/lazywinadmin
#>
	[CmdletBinding()]
	param
	(
		[Parameter(ValueFromPipeline)]
		[ValidateNotNullOrEmpty()]
		[Alias('Text')]
		[System.String[]]$String,

		[Alias("Keep")]
		#[ValidateNotNullOrEmpty()]
		[String[]]$SpecialCharacterToKeep
	)
	PROCESS
	{
		IF ($PSBoundParameters["SpecialCharacterToKeep"])
		{
			$Regex = "[^\p{L}\p{Nd}"
			Foreach ($Character in $SpecialCharacterToKeep)
			{
				IF ($Character -eq "-"){
					$Regex +="-"
				} else {
					$Regex += [Regex]::Escape($Character)
				}
				#$Regex += "/$character"
			}

			$Regex += "]+"
		} #IF($PSBoundParameters["SpecialCharacterToKeep"])
		ELSE { $Regex = "[^\p{L}\p{Nd}]+" }

		FOREACH ($Str in $string)
		{
			Write-Verbose -Message "Original String: $Str"
			$Str -replace $regex, ""
		}
	} #PROCESS
}

Function Connect-O365 {
<#
    .SYNOPSIS
        Connect to O365 tenant and load an Exchange Online session.
		Clobber is allowed.
    .DESCRIPTION
        Entering a bunch of lines to connect to O365 tenant can quickly become really annoying,
		especially if you have to connect to many different tenants. This cmdlet leverages the CredentialManager
		module, but prompts you for a standard prompt if the module was not found.
		This function is heavily based on Microsoft's information.
	.PARAMETER Name
		The name of the credential. Used for naming the files in the credential store.
		The name is not case sensitive. Two files will be used for each credential: '<Name>.username'
		and '<Name>.password'. Whitespace or special characters are not allowed.
	.COMPONENT
		Optional : the CredentialManager module can be leveraged to store and use the Microsoft credential store, 
			allowing us not to have the password stored as a SecureString
			Module CredentialManager from Theo Hardendood, Metis IT B.V.
		If the CredentialManager module is missing, the user will be prompt for its credentials.
	.NOTES
		Adrien LERAYER
		randomitdude.com
		github.com/KoheNC
		v1.0
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false,Position=0,HelpMessage="The name of the credential.")]
        [ValidateNotNullOrEmpty()]
        [string]$CredentialName
    )
	
	Begin
    {
    }
	
	Process{
		# Does the MSOnline module was previously loaded? If not, let's do it
		If (!(Get-Module MSOnline)){
			Import-Module MSOnline -ErrorAction SilentlyContinue

			# Check everything went fine. If there was an error, report it and stop
			If (!$?) { # i know it is not a good practice to use $, but for now i'll use it and change it later
				Write-Host -ForegroundColor Red "There was an error loading the MSOnline module. Exiting..."
				BREAK
			}
		
		}
		# Load the credential
		# Does the CredentialManager module was previously loaded? If not, let's do it
		#If (!(Get-Module $env:GIT_PSModules\00-Common\CredentialManager)){
		If (!(Get-Module CredentialManager)){
			Import-Module CredentialManager -ErrorAction SilentlyContinue

			# Check everything went fine. If there was an error, ask for credential
			If (!$?) { # i know it is not a good practice to use $, but for now i'll use it and change it later
				Write-Host -ForegroundColor Yellow "There was an error loading the CredentialManager module. Please provide credential..."
				$Credential = Get-Credential
			}
		}
		else {
			if(!$CredentialName){
				$Credential = Get-StoredCredential
				Get-Variable Credential | fl
				write-host "salut"
				Set-Variable credential -Scope global
			}
			<# elseif ($CredentialName -and ($CredentialName -notmatch "^\w\w*$")){
				throw "Name cannot contain whitespace or special characters."
			} #>
			else {
				$Credential = Get-StoredCredential -Name $CredentialName
				Get-Variable Credential | fl
			}
		}

		# Connect to O365, create a PSSession to use MS EXchange Online Services, and import it
		Connect-MsolService -Credential $Credential
		$exchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://ps.outlook.com/powershell" -Credential $Credential -Authentication "Basic" -AllowRedirection -verbose
		
		# As the session is nested in a separate module, Powershell sets a scope to the Import-Module cmdlet,
		# and so the result couldn't be used by the caller. So import the PSSession as a module with a global scope
		#Import-Module (Import-PSSession $exchangeSession -DisableNameChecking -AllowClobber -Verbose) -Global
		Import-PSSession $exchangeSession -DisableNameChecking -AllowClobber -Verbose
	}
}

function Split-Array ([object[]]$InputObject,[int]$SplitSize=100)
{
<#
	.EXAMPLE
		$result= Split-Array -InputObject $example -SplitSize 10
#>
	$length=$InputObject.Length
	for ($Index = 0; $Index -lt $length; $Index += $SplitSize)
	{
		#, encapsulates result in array
		#-1 because we index the array from 0
		,($InputObject[$index..($index+$splitSize-1)])
	}
}

function Get-FileEncoding
{
<#
	.SYNOPSIS
	Gets file encoding.
	.DESCRIPTION
	The Get-FileEncoding function determines encoding by looking at Byte Order Mark (BOM).
	Based on port of C# code from http://www.west-wind.com/Weblog/posts/197245.aspx
	.EXAMPLE
	Get-ChildItem  *.ps1 | select FullName, @{n='Encoding';e={Get-FileEncoding $_.FullName}} | where {$_.Encoding -ne 'ASCII'}
	This command gets ps1 files in current directory where encoding is not ASCII
	.EXAMPLE
	Get-ChildItem  *.ps1 | select FullName, @{n='Encoding';e={Get-FileEncoding $_.FullName}} | where {$_.Encoding -ne 'ASCII'} | foreach {(get-content $_.FullName) | set-content $_.FullName -Encoding ASCII}
	Same as previous example but fixes encoding using set-content
#>
    [CmdletBinding()] Param (
     [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)] [string]$Path
    )
 

    [byte[]]$byte = get-content -Encoding byte -ReadCount 4 -TotalCount 4 -Path $Path
 

    if ( $byte[0] -eq 0xef -and $byte[1] -eq 0xbb -and $byte[2] -eq 0xbf )
    { Write-Output 'UTF8' }
    elseif ($byte[0] -eq 0xfe -and $byte[1] -eq 0xff)
    { Write-Output 'Unicode' }
    elseif ($byte[0] -eq 0 -and $byte[1] -eq 0 -and $byte[2] -eq 0xfe -and $byte[3] -eq 0xff)
    { Write-Output 'UTF32' }
    elseif ($byte[0] -eq 0x2b -and $byte[1] -eq 0x2f -and $byte[2] -eq 0x76)
    { Write-Output 'UTF7'}
    else
    { Write-Output 'ASCII' }
}