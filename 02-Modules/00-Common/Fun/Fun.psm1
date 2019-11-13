Function Get-Quotation
{
<#
    .SYNOPSIS
        Display a random quotation.
    .DESCRIPTION
        This function will get a list of random quotes on the net, then 
        stores them in the %localappdata%, one file for one quote.
        Finally, it displays one of them.
    .EXAMPLE
        PS C:\> Get-Quotation
        Nihilism is best done by professionals.
            -- Iggy Pop
    .NOTES
    ORIGINALY TAKEN FROM : https://myotherpcisacloud.com/post/get-quotation-something-for-your-powershell-profile
    Ryan Ries (RR)
    
    Adapted by Adrien LERAYER (AL)
    randomitdude.com
    github.com/KoheNC

    V1.0 : RR, creation
    V1.01 : 2019/05/02, AL : link broken. Change the URL link, parse the result as we have now 4 quotes instead of 1.
            Use of Array and GenericList to adapt the script.
            Addition of comments
#>

    Set-StrictMode -Version Latest
 
    # Prepare the variables
    $Form = @{'number'='1';
              'collection[0]'  = 'devils';
              'collection[1]'  = 'mgm';
              'collection[2]'  = 'motivate';
              'collection[3]'  = 'classic';
              'collection[4]'  = 'coles';
              'collection[5]'  = 'lindsly';
              'collection[6]'  = 'poorc';
              'collection[7]'  = 'altq';
              'collection[8]'  = '20thcent';
              'collection[9]'  = 'bywomen';
              'collection[10]' = 'contrib'}
     
    [String[]]$FormattedQuote = @()
    $Quote = [System.Collections.ArrayList]@()
    $QuoteList = New-Object 'System.Collections.Generic.List[psobject]'
    [bool]$AuthorQuote = $false
    [Int]$MaxWidth = 0

    # Prepare the console width
    If ($Host.Name -EQ 'ConsoleHost')
    {
        $MaxWidth = $Host.UI.RawUI.WindowSize.Width
    }
    Else
    {
        $MaxWidth = 80
    }
 
    # Let's process!
    Try
    {
        #$Page = Invoke-WebRequest http://www.quotationspage.com/random.php3 -Method Post -ContentType 'application/x-www-form-urlencoded' -Body $Form -ErrorAction Stop -TimeoutSec 5 -MaximumRedirection 0
        $Page = Invoke-WebRequest http://www.quotationspage.com/qotd.html -Method Post -ContentType 'application/x-www-form-urlencoded' -Body $Form -ErrorAction Stop -TimeoutSec 5 -MaximumRedirection 0
 
        Foreach ($Element In $Page.AllElements)
        {
            If ($Element.tagName -EQ 'DL')
            {
                [String[]]$PreFormattedQuote = $Element.outerText -Split [Environment]::NewLine               
 
                For ($Index = 0; $Index -LT $PreFormattedQuote.Count; $Index++)
                {
                    If (($PreFormattedQuote[$Index].Length -GT 0) -AND -Not($PreFormattedQuote[$Index].Contains('More quotations on:')))
                    {     
                        # If the line is correct, add it to the array                  
                        $FormattedQuote += $PreFormattedQuote[$Index]

                        # If the current line is the author line, customize it. Otherwise, set the var to announce the next "good line" is the author line
                        If ($AuthorQuote -eq $true)
                        {
                            $FormattedQuote[-1] = "`t-- $($FormattedQuote[-1])"
                            $AuthorQuote = $false
                        }
                        else 
                        {
                            $AuthorQuote = $true
                        } 
                    }                   
                }                 
            }
        }

        # Get a list of quotes. A quote always comes with 2 lines
        [int]$SplitSize = 2
        for ($Index = 0; $Index -LT $FormattedQuote.Count; $Index += $SplitSize)
        {
            $QuoteList.Add(@($FormattedQuote[$index..($index+$splitSize-1)]))
        }

        # Create the directory if it does not exist
        If (-Not(Test-Path (Join-Path $Env:LOCALAPPDATA 'Get-Quotation') -PathType Container))
        {
            New-Item (Join-Path $Env:LOCALAPPDATA 'Get-Quotation') -ItemType Directory | Out-Null
        }

        # Prepare the Hash for the offline files name
        $Hasher = New-Object System.Security.Cryptography.SHA1CryptoServiceProvider

        # Prepare the offline quote files
        For($i = 0; $i -LT $QuoteList.Count; $i++)
        {
            $Hashed = $Hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($QuoteList[$i]))
            [String]$HashString = [BitConverter]::ToString($Hashed).Replace('-', $Null)
            
            # If the offline quote file doesn't exist, create it
            If (-Not(Test-Path (Join-Path (Join-Path $Env:LOCALAPPDATA 'Get-Quotation') $HashString) -PathType Leaf))
            {           
                $QuoteList[$i] | Out-File (Join-Path (Join-Path $Env:LOCALAPPDATA 'Get-Quotation') $HashString)
            }
        }
        
        # Finally, get a quote to display
        $Quote = Get-Random -InputObject $QuoteList
    }
    Catch
    {
        Write-Warning "Failed to get quotation from www.quotationspage.com. ($($_.Exception.Message))"
 
        $Quote = Get-Content ((Get-ChildItem (Join-Path $Env:LOCALAPPDATA 'Get-Quotation') | Get-Random).FullName)
    }
 
    # Word wrap!
    [Int]$Column = 0
    Foreach ($Line in $Quote)
    {
        # If it's the last line of our object, it means we reached the author line. Process then exit.
        If ($Quote.IndexOf($Line) -EQ ($Quote.Length -1))
        {
            Write-Host "`n$Line" -ForegroundColor DarkGray
            Continue
        }
         
        # Otherwise display the quote
        [String[]]$Words = $Line -Split ' '
        Foreach ($Word In $Words)
        {
            # Strip any control characters from the word.
            $Word = $Word.Replace('`r', $Null).Replace('`n', $Null).Replace('`t', $Null)
 
            $Column += $Word.Length + 1  
            If ($Column -GT ($MaxWidth - 8))
            {
                Write-Host
                $Column = 0
            }
            Write-Host "$Word " -NoNewline -ForegroundColor DarkCyan           
        } 
    }
    Write-Host
}

# Next quote on : https://www.brainyquote.com/quote_of_the_day