#requires -Version 7

<#
.SYNOPSIS
    Brute forces a list of web site directories and returns the ones that are successful

.DESCRIPTION
    Queries a provided list file for directories against a provided URL. Returns the
    HTTP Status code of each result. The list file does not have to have extensions
    such as .asp or .html as the script will enumerate them.

.PARAMETER URL
    The URL for the target. Provide the full http://www.* or https://www.* for best results.

.PARAMETER PathList
    The list of directories to tack onto the end of the URL.

.PARAMETER ShowNonHits
    A switch parameter that; by default, filters our directory queries that did not provide
    infomation. Provide this parameter to show the attempts that did not return an HTTP Status
    Code.

.PARAMETER AllowAutoRedirect
    A switch parameter that; by default, restricts the HTTP Request from redirecting. Provide
    this paramter to show the redirects and their URLS.

.EXAMPLE
    ScanDir -URL 'http://www.google.com/' -List '.\dirpath.list'

.EXAMPLE
    ScanDir -URL 'http://www.google.com/' -List '.\dirpath.list' -AllowsAutoRedirect

.EXAMPLE
    ScanDir -URL 'http://www.google.com/' -List '.\dirpath.list' -ShowNonHits

.OUTPUTS
    PSCUSTOMOBJECT

.NOTES
    Author: ergo
#>
function ScanDir{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,
        Position=0,
        ValueFromPipeline=$true)]
        [string]
        $URL,

        [Parameter(Mandatory=$true,
        Position=1)]
        [Alias("List")]
        [ValidateScript({
            if( -Not ($_ | Test-Path) ){
                throw "File or folder does not exist"
            }
            return $true
        })]
        [System.IO.FileInfo]
        $PathList,

        [switch]
        $ShowNonHits,

        [switch]
        $AllowsAutoRedirect
    )

    BEGIN{
        if($URL.EndsWith('/')){
            $URL = $URL.Substring(0,$URL.Length-1)
        }
        $dirList = Get-Content $PathList
        $formattedDirList = New-Object System.Collections.ArrayList
        $dirList | ForEach-Object -ThrottleLimit 50 -Parallel {
            $newList = $using:formattedDirList
            $null = $newList.Add($_ + '.html')
            $null = $newList.Add($_ + '.asp')
            $null = $newList.Add($_ + '.aspx')
            $null = $newList.Add($_ + '.txt')
            $null = $newList.Add($_ + '.xml')
        }
        $null = $formattedDirList.AddRange($dirList)
        $results = New-Object System.Collections.ArrayList
    }
    PROCESS{
        $formattedDirList | ForEach-Object -ThrottleLimit 15 -Parallel {
            $results = $using:results
            $dir = $_
            if($dir.StartsWith('/')){
                $dir = $dir.Substring(1)
            }
            if(![string]::IsNullOrWhitespace($dir)){
                $URI = $using:URL + '/' + $dir
                $httpRequest = [System.Net.WebRequest]::Create($URI)
                $httpRequest.AllowAutoRedirect = $using:AllowsAutoRedirect
                try{
                    $httpResponse = $httpRequest.GetResponse()
                    $httpStatus = [int]$httpResponse.StatusCode
                }
                catch{
                    $httpStatus = -1
                }

                if($using:AllowsAutoRedirect){
                    $obj = [pscustomobject]@{
                        'URI' = $URI
                        'dir' = $dir
                        'HttpStatus' = $httpStatus
                        'Redirected URI' = $httpResponse.ResponseUri
                    }
                } else{
                    $obj = [pscustomobject]@{
                        'URI' = $URI
                        'dir' = $dir
                        'HttpStatus' = $httpStatus
                    }
                }
                try{
                    $null = $results.Add($obj)
                } catch{
                    Write-Verbose $Error[0]
                }
            }
        }
    }
    END{
        if($ShowNonHits){
            $results = $results | Sort-Object -Property HttpStatus -Descending
            $results
        } else{
            $results = $results | Where-Object {$_.HttpStatus -ne -1} | Sort-Object -Property HttpStatus
            $results
        }

        if($null -eq $httpResponse){}
        else{$httpResponse.Close()}
    }
}