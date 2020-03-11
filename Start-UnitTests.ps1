#Requires -Modules @{ModuleName='Pester';ModuleVersion='4.10.1'}

$testDir = [System.IO.Path]::Combine($PSScriptRoot, 'tests')

Invoke-Pester -Script $testDir