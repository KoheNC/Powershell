$CSVfile = "c:\ava6\Export-ADGroupMembers.csv"
$AllSG = Get-ADGroup -Filter *
$output = @()
Foreach($SG in $AllSG){
    $Members = Get-ADGroupMember $SG.SamaccountName

    if($members.count -eq 0){
        $userObj = New-Object PSObject
        $userObj | Add-Member NoteProperty -Name "GroupName" -Value $SG.Name
        $userObj | Add-Member NoteProperty -Name "GroupSam" -Value $SG.SamaccountName
        $userObj | Add-Member NoteProperty -Name "UserDisplayName" -Value EmtpyGroup
        $userObj | Add-Member NoteProperty -Name "MemberSam" -Value EmtpyGroup
        $userObj | Add-Member NoteProperty -Name "MemberDN" -Value EmtpyGroup
        $output += $userObj
    }
    else {
        Foreach($Member in $members) {
            $userObj = New-Object PSObject
            $userObj | Add-Member NoteProperty -Name "GroupName" -Value $SG.Name
            $userObj | Add-Member NoteProperty -Name "GroupSam" -Value $SG.SamaccountName
            $userObj | Add-Member NoteProperty -Name "UserDisplayName" -Value $member.Name
            $userObj | Add-Member NoteProperty -Name "MemberSam" -Value $member.SamaccountName
            $userObj | Add-Member NoteProperty -Name "MemberDN" -Value $member.DistinguishedName
            $output += $userObj
        }
    }
}

# update counters and write progress
$i++
Write-Progress -activity "Scanning Groups . . ." -status "Scanned: $i of $($allSg.Count)" -percentComplete (($i / $allSg.Count)  * 100)
$output | Export-csv -Path $CSVfile -encoding "unicode" -Delimiter ";"
