##########################################################################################################
<#

.SYNOPSIS
   Queries a target DC for trusts detailing the status of any found in a CSV file

.DESCRIPTION
   Uses WMI or CIM to get trust status for all trusts in a domain. 

   Requires: * WMI connectivity (DCOM)
             * CIM connectivity (WinRM) if -CIM switch supplied
             * Parameter 1: target Domain Controller

   See here for more information on sID Filtering check:

    http://blogs.technet.com/b/poshchap/archive/2015/12/11/security-focus-sidhistory-sid-filtering-sanity-check-part-2.aspx

.EXAMPLE
   .\Get-ADTrustStatus.ps1 contosodc01

   Uses WMI to connect to contosodc01. Write trusts status for the domain that contosodc01 is a  domain 
   controller for to a time and date stamped CSV file, e.g. 20131114195001_Trust_Status.csv

.EXAMPLE
   .\Get-ADTrustStatus.ps1 -DC contosodc02 -CIM

   Uses CIM to connect to contosodc02. Write trusts status for the domain that contosodc02 is a  domain 
   controller for to a time and date stamped CSV file, e.g. 20131125194501_Trust_Status.csv

.OUTPUTS
    Time and date stamped CSV file, e.g. 20131114195001_Trust_Status.csv

.NOTES
    THIS CODE-SAMPLE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED 
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR 
    FITNESS FOR A PARTICULAR PURPOSE.

    This sample is not supported under any Microsoft standard support program or service. 
    The script is provided AS IS without warranty of any kind. Microsoft further disclaims all
    implied warranties including, without limitation, any implied warranties of merchantability
    or of fitness for a particular purpose. The entire risk arising out of the use or performance
    of the sample and documentation remains with you. In no event shall Microsoft, its authors,
    or anyone else involved in the creation, production, or delivery of the script be liable for 
    any damages whatsoever (including, without limitation, damages for loss of business profits, 
    business interruption, loss of business information, or other pecuniary loss) arising out of 
    the use of or inability to use the sample or documentation, even if Microsoft has been advised 
    of the possibility of such damages, rising out of the use of or inability to use the sample script, 
    even if Microsoft has been advised of the possibility of such damages. 

#>
<#
A few things to note:
	The script tests the domain of the targeted DC
	The script tests all trusts types, not just Forest and External. Intra-Forest trusts will flag as having sID Filtering (quarantine) disabled - this is default.
	The script will identify Forest and Intra-Forest trusts. External trusts will not be called out but can be assumed to be those that are marked as both false in IS_FOREST and IS_INTRA_FOREST. NB - other trust types, e.g. shortcut, will flag as false / false too.
	The script doesn't use Get-ADTrust, rather it uses the WMI / CIM Microsoft_DomainTrustStatus class from the Root/MicrosoftActiveDirectory namespace. This exposes the trustAttributes property of each Trusted Domain Object (TDO). The trustAttributes property is then used to determine the whether sID Filtering is disabled on the trust. For a forest trust, if a value of 64 is contained within the property then we have forest aware sIDFIltering disabled on the trust. For an external trust if a value of 4 is contained within the trustAttributes property then we have sID Filtering quarantine enabled on the trust
#>
##########################################################################################################

##Script Options and Parameters

#Requires -version 3
#Requires -modules ActiveDirectory

#Version: 2.2
<# - 18/11/2015 
     * added ability to report on sID Filtering

   - 07/12/2015
     * added is_Forest and is_Intra_Forest check
#>

#Define and validate parameters
[CmdletBinding()]
Param(
      #The target domain controller
      [parameter(Mandatory=$True,Position=1)]
      [ValidateScript({Get-ADDomainController -Identity $_})]
      [String]$DC,

      #Use CIM rather than WMI
      [Switch] 
      $CIM
      )


##########################################################################################################

##Constants

#Trust Direction
New-Variable -Name Inbound_Trust -Value 1 -Option Constant
New-Variable -Name Outbound_Trust -Value 2 -Option Constant
New-Variable -Name BiDirectional_Trust -Value 3 -Option Constant

#Trust Attributes
New-Variable -Name sIDFiltering_Quarantined -Value 4 -Option Constant    #sID Filtering applied (quarantine)
New-Variable -Name Forest_Transitive -Value 8 -Option Constant           #Forest Transitive Trust
New-Variable -Name Intra_Forest -Value 32 -Option Constant               #Intra Forest Trust
New-Variable -Name sIDFiltering_ForestAware -Value 64 -Option Constant   #sID Filtering applied (forest aware)



##########################################################################################################

##Main

#Create a variable to represent a new report file, constructing the report name from date details (padded)
$SourceParent = (Get-Location).Path
$Date = Get-Date
$NewReport = "$SourceParent\" + `
             "_Trust_Status.csv"


#Run WMI or CIM query against specified Domain Controller to obtain just NT trusts
If ($CIM) {

}   #End of Else ($CIM)


#Check whether the WMI query has returned any objects
If ($Trusts -ne $Null) {

    #Create CSV file headers
    Add-Content -Path $NewReport -Value "TRUSTED_DOMAIN,TRUST_IS_OK,TRUST_STATUS,TRUST_STATUS_STRING,TRUST_DIRECTION,IS_FOREST,IS_INTRA_FOREST,SIDFILTERING_FORESTAWARE_DISABLED,SIDFILTERING_QUARANTINE_ENABLED"

    #Loop through each trust and report upon its status
    ForEach ($Trust in $Trusts) {

        #Get Trust Direction status
        Switch ($Trust.TrustDirection) {

            $Inbound_Trust {$Direction = "Inbound"}

            $Outbound_Trust {$Direction = "Outbound"}

            $BiDirectional_Trust {$Direction = "BiDirectional"}

        }


        <#
        Trust type (forst vs. intra-forest)
        No check for other types, e.g. external, (will add later)
        #> 
        $isForest = $false
        $isIntra = $false

        #Check for forest trust
        if ($Trust.trustAttributes -band $Forest_Transitive) {

            $isForest = $True

        }

        #Check for intra-forest truist
        if ($Trust.trustAttributes -band $Intra_Forest) {

            $isIntra = $True

        }


        #Get sIDFiltering status
        $ForestAware = $false
        $Quarantine = $false

        #Check for sID Filtring disabled on forest trusts
        if ($Trust.trustAttributes -band $sIDFiltering_ForestAware) {

            $ForestAware = $true
        }

        #Check for sID FIltering enabled on trusts
        if ($Trust.trustAttributes -band $sIDFiltering_Quarantined) {

            $Quarantine = $true
        }


        #Use Add-Content to update the CSV file with this object's properties
        Add-Content -Path $NewReport -Value "$($Trust.TrustedDomain),$($Trust.TrustIsOk),$($Trust.TrustStatus),`"$($Trust.TrustStatusString)`",$Direction,$isForest,$isIntra,$ForestAware,$Quarantine"
    
    }   #End of ForEach ($Trust in $Trusts)

}   #End of If ($Trusts -ne $Null)

Else {

    #Display update message to console
    $Message = "Trusts were NOT found when querying $DC"
        Write-Host 
        Write-Host ("=" * ($Message).Length)
        Write-Host $Message
        Write-Host ("=" * ($Message).Length)

}   #End of Else ($Trusts -ne $Null)