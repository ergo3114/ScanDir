#requires -Version 7

function ScanDir{
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
            $results | Sort-Object -Property HttpStatus -Descending
        } else{
            $results | Where-Object {$_.HttpStatus -ne -1} | Sort-Object -Property HttpStatus
        }

        if($null -eq $httpResponse){}
        else{$httpResponse.Close()}
    }
}