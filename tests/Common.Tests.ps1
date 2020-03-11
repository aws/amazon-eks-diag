# Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# or in the "license" file accompanying this file. This file is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied. See the License for the specific language governing
# permissions and limitations under the License.

<#
Pester test file intended to run as a part of testing code changes.
Not intended to run as a part of the diagnostic tool's execution.
#>
$moduleName = 'amazon-eks-diag'
Write-Host ('Reloading module: {0}' -f $moduleName)
Remove-Module $moduleName -Force -ErrorAction:SilentlyContinue
$moduleManifest = [System.IO.Path]::Combine($PSScriptRoot, "..\$moduleName", "$moduleName.psd1")
Import-Module $moduleManifest -Force
if ($null -eq (Get-Module -Name $moduleName)) {
    Throw 'Module not loaded'
    return
}
$moduleFile = (Get-Module -Name $moduleName).Path
Describe "$moduleName Module Structure" {
    $moduleDir = (Get-Item -Path $moduleFile).Directory.FullName
    $functionDir = [System.IO.Path]::Combine($moduleDir, 'functions')
    $publicFunctionFiles = Get-ChildItem -Path "$functionDir\public\*" -Include *.ps1 -Exclude *.tests.ps1 -Recurse
    $privateFunctionFiles = Get-ChildItem -Path "$functionDir\private\*" -Include *.ps1 -Exclude *.tests.ps1 -Recurse
    $testDir = [System.IO.Path]::Combine($moduleDir, 'Tests')

    Context "Module Manifest Checks" {
        It "has a valid manifest (psd1)" {
            { Test-ModuleManifest -Path $moduleManifest } | Should Not Throw
        }
    }

    Context "Each $moduleName public function should be exported" {
        Foreach ($file in $publicFunctionFiles) {
            $functionName = (Get-Item -Path $file).BaseName
            It "$functionName is an exported commandlet" {
                { Get-Command -Module $moduleName -Name $functionName } | Should Not Throw
                Get-Command -Module $moduleName -Name $functionName | Should Not Be $null
            }
        }
    }

    Context "Each $moduleName private function should not be exported" {
        Foreach ($file in $privateFunctionFiles) {
            $functionName = (Get-Item -Path $file).BaseName
            It "$functionName is not an exported commandlet" {
                { Get-Command -Module $moduleName -Name $functionName } | Should Throw
            }
        }
    }

    Context "Each $moduleName function should have its own script file" {
        $moduleCommands = Get-Command -Module $moduleName
        Foreach ($moduleCommand in $moduleCommands) {
            It "$moduleCommand has its own script file: $moduleCommand.ps1" {
                [System.IO.FileInfo[]]$scriptFiles = Get-ChildItem -Path "$functionDir\*" -Include *.ps1 -Exclude *.tests.ps1 -Recurse | Where-Object {
                    $_.BaseName -eq $moduleCommand
                }
                $scriptFiles | Should Not Be $null
                $scriptFiles.Count | Should Be 1
                Test-Path -Path $scriptFiles.FullName | Should Be $true
            }
        }
    }
}