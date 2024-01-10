#Requires -Version 5.0
using namespace System.Management.Automation

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

function Rename-PSHost ([string]$NewHostUIName)
{
	$host.ui.RawUI.WindowTitle = $NewHostUIName
}