BeforeAll{
    $sut = ($PSCommandPath -split '\\')[-1].Replace('.Tests','')
    . $PSScriptRoot\..\$sut
}

Describe "ScanDir"{
    It "Should error when a path to a dir list is invalid" {
        { ScanDir -URL 'https://google.com' -List 'C:\paththatdoesnotexist\filethatdoesnotexist.list' } | Should -Throw
    }
}