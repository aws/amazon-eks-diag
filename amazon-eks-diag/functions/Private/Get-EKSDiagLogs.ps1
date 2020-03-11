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
Function Get-EKSDiagLogs {
    <#
    .SYNOPSIS
    Recursively searches the target directory for logs and copies them to the target location
    
    .DESCRIPTION
    Recursively searches the target directory for logs and copies them to the target location
    
    .PARAMETER LogDir
    The source directory to search under
    
    .PARAMETER LogTypes
    The string array of files types to include. The array is passed as an "Include" and supports
    wildcards

    .PARAMETER Exclude
    The string array of file names to exclude. The array is passed as an "Exclude" and supports
    wildcards
    
    .PARAMETER Path
    The location to copy log files to
    #>
    
    Param (
        [Parameter(Mandatory = $true)]
        [string]$LogDir,

        [Parameter(Mandatory = $false)]
        [string[]]$LogTypes = @('*.log', '*.txt'),

        [Parameter(Mandatory = $false)]
        [string[]]$Exclude = @(),

        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    $ErrorActionPreference = 'Continue'
    Set-StrictMode -Version latest

    Write-Log ('Checking for logs found under {0}' -f $LogDir)
    $params = @{
        Path    = $LogDir
        Recurse = [switch]::Present
    }
    if (-not [string]::IsNullOrEmpty($LogTypes)) {
        $params += @{
            Include = $LogTypes
        }
    }
    if (-not [string]::IsNullOrEmpty($Exclude)) {
        $params += @{
            Exclude = $Exclude
        }
    }
    $logs = Get-ChildItem @params
    if ($null -eq $logs) {
        Write-Log ('No logs found under {0}' -f $LogDir)    
        return
    } elseif (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -ItemType:Directory | Out-Null
    }
    
    Foreach ($logFile in $logs) {
        Write-Log ('Copying {0} to {1}' -f $logFile, $Path)
        Copy-Item -Path $logFile -Destination $Path
    }
}