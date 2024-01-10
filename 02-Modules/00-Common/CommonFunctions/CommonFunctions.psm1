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