<#
	https://blogs.technet.microsoft.com/poshchap/2016/06/10/security-focus-adminsd-holder-acl/
	Do a "Compare-Object" to see differences between 2 reports
#>
#Loop through each domain in the forest

(Get-ADForest).Domains | ForEach-Object {

    #Get System Container path

    $Domain = Get-ADDomain -Identity $_

    #Connect a PS Drive

    $Drive = New-PSDrive -Name $Domain.Name -PSProvider ActiveDirectory -Root $Domain.SystemsContainer -Server $_

    #Export AdminSDHolder ACL

    if ($Drive) {

        $Acl = (Get-Acl "$($Drive.Name):CN=AdminSDHolder").Access

        if ($Acl) {

            $Acl | Export-Clixml -Path ".\$(($Domain.Name).ToUpper())_ADMINSDHOLDER_ACL_FULL.xml"

            $Acl | Select-Object -Property IdentityReference -Unique | Export-Csv -Path ".\$(($Domain.Name).ToUpper())_ADMINSDHOLDER_ACL_GROUPS.csv"

        }

        #Remove PS Drive

        Remove-PSDrive -Name $Domain.Name

    }

}