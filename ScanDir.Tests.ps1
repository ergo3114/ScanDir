BeforeAll{
    . $PSCommandPath.Replace('.Tests.ps1','.ps1') 
}

Describe "ScanDir"{
    It "Should error when a path to a dir list is invalid" {
        { ScanDir -URL 'https://google.com' -List 'C:\paththatdoesnotexist\filethatdoesnotexist.list' } | Should -Throw
    }
}