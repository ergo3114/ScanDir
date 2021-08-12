Describe "Metadata"{
    BeforeAll{
        Set-Location $PSScriptRoot
        Set-Location ..
        $psscripts = $((Get-ChildItem "*.ps1").Name)
        foreach($psscript in $psscripts){
            . .\$psscript
        }
    }

    It "Should have a LICENSE file" {
        (Get-ChildItem LICENSE).Name | Should -Be 'LICENSE'
    }

    It "Should have a README.md file" {
        (Get-ChildItem README.md).Name | Should -Be 'README.md'
    }

    $FunctionsList = (Get-Command ScanDir).Name

    FOREACH($Function in $FunctionsList){
        $Help = Get-Help -Name $Function -Full

        Context "$Function - Help"{
            It "Synopsis"{$Help.Synopsis | Should -Not -BeNullOrEmpty}
            It "Description"{$Help.Description | Should -Not -BeNullOrEmpty}
            It "Examples"{$Help.Examples.Example.Code.Count | Should -BeGreaterThan 0}
        }
    }
}