#Requires -Version 5.0
using namespace System.Management.Automation

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