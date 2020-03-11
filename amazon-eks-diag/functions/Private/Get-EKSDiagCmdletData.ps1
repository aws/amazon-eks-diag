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
Function Get-EKSDiagCmdletData {
    <#
    .SYNOPSIS
    Executes the given powershell command and parameters, and logs the returned powershell objects as json
    
    .DESCRIPTION
    Executes the given powershell command and parameters, and logs the returned powershell objects as json
    
    .PARAMETER Command
    The powershell commandlet to execute
    
    .PARAMETER Parameters
    The parameters to pass to the commandlet. Parameters are interpreted as a hashtable and sent to the
    commandlet using splatting
    
    .PARAMETER Path
    The location to log the json objects to
    #>
    
    Param (
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory = $true)]
        [hashtable]$Parameters,

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if ($null -ne $Parameters) {
        $cmd = "$Command @Parameters"
    } else {
        $cmd = $Command
    }
    
    $return = $null
    try {
        $return = Invoke-Expression -Command $cmd
    } catch {
        $_.Exception.Message | Tee-Object -FilePath "$Path.exception.log" -Append | Write-Log -IsError
    }
    if ($null -ne $return) {
        try { # log the json
            [string]$json = ConvertTo-Json -InputObject $return -Depth $Global:EKSDiag_ObjectJsonDepth
            Add-EKSDiagJsonData -Name $Command -Value $json -Path $Path -Depth $Global:EKSDiag_ObjectJsonDepth
        } catch { # Else log the plain text
            Out-File -InputObject $return -FilePath "$Path.exception.log" -Append
        }
        
    }
}