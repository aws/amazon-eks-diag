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
Function Write-Log {
    [CmdletBinding()]
    Param (
        [Parameter(
            Position=0, 
            Mandatory=$true, 
            ValueFromPipeline=$true
        )]
        [String]$Message,

        [Parameter(
            Position=1, 
            Mandatory=$false
        )]
        [switch]$IsError
    )
    $ErrorActionPreference = 'Stop'
    Set-StrictMode -Version latest
    
    if ($IsError) {
        $eap = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        Write-Error "An exception was caught: `n$Message"
        $ErrorActionPreference = $eap
        $Message = "[ERROR]: $Message"
    }
    $fullMessage = ('{0} - {1} [{2}]' -f $(Get-Date -Format 'yyyy.MM.dd HH:mm:ss'),
                                        $Message,
                                        $Global:EKSDiag_SW.Elapsed.TotalSeconds)
    Write-Host $fullMessage
    Out-File -InputObject $fullMessage -FilePath $Global:EKSDiag_Log -Append
}