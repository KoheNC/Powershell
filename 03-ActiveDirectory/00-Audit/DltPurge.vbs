'==============================================================================
'==============================================================================
'
' Copyright (C) 2001 by Microsoft Corporation.  All rights reserved.
'
' This script deletes all Active Directory objects used by the
' Distributed Link Tracking Server service.
'
' It is assumed that the DLT Server service has been disabled,
' and you wish to recover the DIT space these objects occupy.
'
' Usage:   cscript DltPurge.vbs <options>
' Options: -s ServerName
'          -d distinguishedname dc=mydomain,dc=mycompany,dc=com
'          -b BatchSize  BatchDelayMinutes
'          -t (optional test mode)
'
'	Example: 
'		cscript dltpurge.vbs -s myserver -d dc=mydomain,dc=mycompany,dc=com
'	In this command line: 
'		-s is the DNS host name of the domain controller on which you want to delete Distributed Link Tracking objects.
'		-d is the distinguished name path of the domain on which you want to delete Distributed Link Tracking objects.
'
' The objects are deleted in batches - BatchSize objects are deleted,
' then there is a BatchDelayMinutes delay before the next batch.
'
'==============================================================================
'==============================================================================

Option Explicit

'
' Globals, also local to main.
'
Dim oProvider
Dim oTarget
Dim sServer
Dim sDomain
Dim bTest

Dim BatchSize
Dim BatchDelayMinutes

'
' Set defaults
'

BatchSize = 1000
BatchDelayMinutes = 15
bTest = False

'==============================================================================
'
'   ProcessArgs
'
'   Parse the command-line arguments.  Results are set in global variables
'   (oProvider, oTarget, sServer, sDomain, BatchSize, and BatchDelayMinutes).
'
'==============================================================================


public function ProcessArgs

    Dim iCount
    Dim oArgs

    on error resume next

    '
    ' Get the command-line arguments
    '
    
    Set oArgs = WScript.Arguments

    if oArgs.Count > 0 then

        '
        ' We have command-line arguments.  Loop through them.
        '

        iCount = 0
        ProcessArgs = 0

        do while iCount < oArgs.Count

            select case oArgs.Item(iCount)

                '
                ' Server name argument
                '
                
                case "-s"

                    if( iCount + 1 >= oArgs.Count ) then
                        Syntax
                        ProcessArgs = -1
                        exit do
                    end if

                    sServer = oArgs.Item(iCount+1)
                    if Len(sServer) > 0 then sServer = sServer & "/"
                    iCount = iCount + 2

                '
                ' Enable testing option
                '
                
                case "-t"

                    iCount = iCount + 1
                    bTest  = True

                '
                ' Domain name option
                '
                
                case "-d"

                    if( iCount + 1 >= oArgs.Count ) then
                        Syntax
                        ProcessArgs = -1
                        Exit Do
                    end if

                    sDomain = oArgs.Item(iCount+1)
                    iCount = iCount + 2

                '
                ' Batching option (batch size, batch delay)
                '

                case "-b"

                    if( iCount + 2 >= oArgs.Count ) then
                        Syntax
                        ProcessArgs = -1
                        exit do
                    end if

                    Err.Clear
                    
                    BatchSize = CInt( oArgs.Item(iCount+1) )
                    BatchDelayMinutes = CInt( oArgs.Item(iCount+2) )
                    
                    if( Err.Number <> 0 ) then 
                        wscript.echo "Invalid value for -b argument" & vbCrLf
                        Syntax
                        ProcessArgs = -1
                        exit do
                    end if
                    
                    iCount = iCount + 3

                '
                ' Help option
                '
                
                case "-?"
                    Syntax
                    ProcessArgs = -1
                    exit do

                '
                ' Invalid argument
                '
                
                case else
                
                    ' Display the syntax and return an error

                    wscript.echo "Unknown argument: " & oArgs.Item(iCount) & vbCrLf
                    Syntax
                    ProcessArgs = -1
                    Exit Do
                    
            end select
      loop

    else
    
        '
        ' There were no command-line arguments, display the syntax
        ' and return an error.
        '

        Syntax
        ProcessArgs = -1

    end if

    Set oArgs = Nothing

end function ' ProcessArgs

'==============================================================================
'
'   Syntax
'
'   Show the command-line syntax
'
'==============================================================================

public function Syntax

    wscript.echo    vbCrLf & _
                    "Purpose:   Delete Active Directory objects from Distributed Link Tracking" & vbCrLf & _
                    "           Server service (Assumes that DLT Server has been disabled" & vbCrLf & _
                    "           on all DCs)" & vbCrLf & _
                    vbCrLf & _
                    "Usage:     " & wscript.scriptname & " <arguments>" & vbCrLf & _
                    vbCrLf & _
                    "Arguments: -s Server" & vbCrLf & _
                    "           -d FullyQualifiedDomain" & vbCrLf & _
                    "           -b BatchSize BatchDelayMinutes (default to 1000 and 15)" & vbCrLf & _
                    "           -t (optional test mode, nothing is deleted)" & vbCrLf & _
                    vbCrLf & _
                    "Note:      Objects are deleted in batches, with a delay between each" & vbCrLf & _
                    "           batch.  The size of the batch defaults to 1000 objects, and" & vbCrLf & _
                    "           the length of the delay defaults to 15 minutes.  But these" & vbCrLf & _
                    "           values can be overridden using the -b option." & vbCrLf & _
                    vbCrLf & _
                    "Example:   " & wscript.scriptname & "  -s  myserver  -d distinguishedname dc=mydomain,dc=mycompany,dc=com "

end function    ' Syntax



'==============================================================================
'
'   PurgeContainer
'
'   Delete all objects of the specified class in the specified container.
'   This subroutine is called once for the volume table and once for
'   the object move table.
'
'==============================================================================

sub PurgeContainer(ByRef oParent, ByVal strClass)

    dim oChild
    dim iBatch
    dim iTotal

    On Error Resume Next

    iTotal = 0
    iBatch = 0

    ' Loop through the children of this container

    For Each oChild in oParent

        ' 
        ' Is this a DLT object?
        '

        
        if oChild.Class = strClass Then

            '
            ' Yes, this is a DLT object, it may be deleted
            '
            
            iTotal = iTotal + 1
            iBatch = iBatch + 1

            '
            ' Delete the object
            '
            
            if bTest then
                wscript.echo "Object that would be deleted: " & oChild.adspath
            else
                oParent.Delete oChild.Class, oChild.Name
            end if

            '
            ' If this is the end of a batch, delay to let replication
            ' catch up.
            '
            
            if iBatch = BatchSize then
            
                iBatch = 0
                
                wscript.stdout.writeline "" ' ignored by wscript
                wscript.echo "Deleted " & BatchSize & " objects"
                wscript.echo "Pausing to allow processing (will restart at " & DateAdd("n", BatchDelayMinutes, Time) & ")"
                
                wscript.sleep BatchDelayMinutes * 60 * 1000
                wscript.echo "Continuing ..."
                
            end if
            
        else
        
            ' oChild.Class didn't match strClass
            wscript.echo "Ignoring unexpected class: " & oChild.Class
            
        end if

        oChild = NULL

    Next


    wscript.echo "Deleted a total of " & iTotal & " objects"

end sub ' PurgeContainer


'==============================================================================
'
' Main
'
'==============================================================================

if (ProcessArgs=-1) then wscript.quit

on error resume next

'
' Explain what's about to happen
'

wscript.stdout.writeline "" ' ignored by wscript
wscript.echo "This script will purge all objects from the Active Directory" & vbCrLf & _
             "used by the Distributed Link Tracking Server service (trksvr)." & vbCrLf & _
             "It is assumed that this service has already been disabled on" & vbCrLf & _
             "all DCs in the domain."

'
' When running in cscript, pause to give an opportunity to break out
' (These 3 lines are for cscript and ignored by wscript.)
'

wscript.stdout.writeline ""
wscript.stdout.writeline "Press Enter to continue ..."
wscript.stdin.readline

'
' Get an ADSI object
'

Set oProvider = GetObject("LDAP:")

'
' Purge the System/FileLinks/ObjectMoveTable
'

wscript.stdout.writeline "" ' ignored by wscript
wscript.echo "Purging ObjectMoveTable"

Set oTarget = oProvider.OpenDSObject( "LDAP://" & sServer  & "cn=ObjectMoveTable,CN=FileLinks,CN=System," & sDomain ,_
                                      vbNullString, vbNullString, _
                                      1) ' ADS_SECURE_AUTHENTICATION

call PurgeContainer( oTarget, "linkTrackOMTEntry" )
oTarget = NULL

'
' Purge the System/FileLinks/VolumeTable
'

wscript.stdout.writeline "" ' ignored by wscript
wscript.echo "Purging VolumeTable"

Set oTarget = oProvider.OpenDSObject("LDAP://" & sServer  & "cn=VolumeTable,CN=FileLinks,CN=System," & sDomain  ,_
                                     vbNullString, vbNullString, _
                                     1) ' ADS_SECURE_AUTHENTICATION
call PurgeContainer( oTarget, "linkTrackVolEntry" )
oTarget = NULL

oProvider = NULL