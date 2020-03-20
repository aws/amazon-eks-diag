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

Function Get-EKSDiagExeData {
    <#
    .SYNOPSIS
    Executes an expression, and logs the output

    .DESCRIPTION
    Executes an expression, and logs the output

    .PARAMETER Command
    The expression as a command to run

    .PARAMETER Path
    The location to log the output of the command
    #>

    Param (
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )
    $ErrorActionPreference = 'Continue'
    Out-File -InputObject "`n$((Get-Location).Path)> $command`n" -FilePath $Path -Append
    try {
        Invoke-Expression -Command $Command *>>$Path 2>>"$Path.exception.log"
    }
    catch {
        $_.Exception.Message | Tee-Object -FilePath "$Path.exception.log" -Append | Write-Log -IsError
    }
}