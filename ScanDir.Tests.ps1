BeforeAll{
    . $PSCommandPath.Replace('.Tests.ps1','.ps1') 
}

Describe "Metadata"{
    It "Should have a LICENSE file" {
        (Get-ChildItem LICENSE).Name | Should -Be 'LICENSE'
    }

    It "Should have a README.md file" {
        (Get-ChildItem README.md).Name | Should -Be 'README.md'
    }
}

Describe "ScanDir"{
    It "Should error when a path to a dir list is invalid" {
        { ScanDir -URL 'https://google.com' -List 'C:\paththatdoesnotexist\filethatdoesnotexist.list' } | Should -Throw
    }
}