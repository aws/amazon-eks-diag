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
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version latest

Write-Verbose "Importing Private helper functions from $([System.IO.Path]::Combine($PSScriptRoot, 'Functions\Private\*'))"
Get-ChildItem -Path $([System.IO.Path]::Combine($PSScriptRoot, 'Functions\Private\*')) -Recurse -Include *.ps1 | Foreach-Object {
    . $_.FullName
}

Write-Verbose "Importing Public functions from $([System.IO.Path]::Combine($PSScriptRoot, 'Functions\Public\*'))"
Get-ChildItem -Path $([System.IO.Path]::Combine($PSScriptRoot, 'Functions\Public\*')) -Recurse -Include *.ps1 | Foreach-Object {
    . $_.FullName
    Export-ModuleMember -Function $($_.BaseName)
}
