Import-Module ActiveDirectory

$AllSG_GG = Get-ADGroup -Filter * -Properties * -SearchBase "OU=Test,OU=0 - Groupes transverses,DC=mairie-seynod,DC=lan" | ? Name -like "GG_*"
$AllSG_G = Get-ADGroup -Filter * -Properties * -SearchBase "OU=Test,OU=0 - Groupes transverses,DC=mairie-seynod,DC=lan" | ? Name -like "G_*"

$count1 = 0
$count2 = 0

Foreach($SG_GG in $AllSG_GG){
    $oldName = $SG_GG.Name
    $oldDistinguishedName = $SG_GG.DistinguishedName
    $newName = $oldName -replace "GG_","GG_ALV_"
    Set-ADGroup -Identity $oldName -SamAccountName $newName
    Rename-ADObject -Identity $oldDistinguishedName -NewName $newName

    Write-Host "Le groupe" $oldName "a ete renomme en" $newName
    $count1++
}

Foreach($SG_G in $AllSG_G){
    $oldName = $SG_G.Name
    $oldDistinguishedName = $SG_G.DistinguishedName
    $newName = $oldName -replace "GG_","GG_ALV_"
    Set-ADGroup -Identity $oldName -SamAccountName $newName
    Rename-ADObject -Identity $oldDistinguishedName -NewName $newName

    Write-Host "Le groupe" $oldName "a ete renomme en" $newName
    $count2++
}

Write-Host "Nombre de groupe commencant par GG_ renommes" $count
Write-Host "Nombre de groupe commencant par G_ renommes" $count

