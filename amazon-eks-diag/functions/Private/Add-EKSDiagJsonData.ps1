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

Function Add-EKSDiagJsonData {
    <#
    .SYNOPSIS
    Logs json to a file by appending objects together using the key name

    .DESCRIPTION
    Logs json to a file by appending objects together using the key name

    .PARAMETER Name
    The key name of the json object to append the input json to

    .PARAMETER Value
    The input json blob as a string

    .PARAMETER Path
    The location of the file to append to

    .PARAMETER Depth
    The json depth to parse. Defaults to 10
    #>

    Param (
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory = $true)]
        [string]$Value,

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory = $false)]
        [int]$Depth = 10
    )
    $obj = $null
    if (Test-Path -Path $Path) {
        [PSObject]$obj = Get-Content -Path $Path | ConvertFrom-Json
        [PSObject[]]$obj.$Name += $($Value | ConvertFrom-Json)
    }
    else {
        $obj = New-Object PSObject
        Add-Member -InputObject $obj -MemberType:NoteProperty -Name $Name -Value @($($Value | ConvertFrom-Json))
    }
    $json = ConvertTo-Json -InputObject $obj -Depth $Depth
    Out-File -InputObject $json -FilePath $Path -Force -Confirm:$false
}