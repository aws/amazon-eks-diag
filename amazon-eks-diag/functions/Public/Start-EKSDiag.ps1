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

Function Start-EKSDiag {
    <#
    .DESCRIPTION A function to help Amazon EKS users gather diagnostic
    information from their Amazon EC2 Windows worker nodes.

    .SYNOPSIS Gathers an archives diagnostic logs and information related
    to the local EKS Windows worker node. Gathers the local diagnostic
    information for this node only, and compresses the information into an
    archive. For security, the archive is left on the local file system for
    the system administrator to choose an apropriate mechanism for retrieving
    the archive.

    .PARAMETER Guid
    A unique string used to tag the resulting diagnostic information. Defaults
    to a date-based string using the format 'yyyyMMdd_HHmmss'

    .PARAMETER Path
    The location where diagnostic information should be stored. Defaults
    to a directory under $ENV:Temp named with a prefix of 'EKSDiag_' and a
    suffix of $Guid

    .PARAMETER LogLevel
    The verbosity of the diagnostic information gathered represented as an [int]
    between 1-5. Defaults to 1
    #>
    [CmdletBinding()]
    Param (
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory = $false)]
        [string]$Guid = $(Get-Date -Format 'yyyyMMdd_HHmmss'),

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory = $false)]
        [string]$Path = [System.IO.Path]::Combine($ENV:Temp, "EKSDiag_$Guid"),

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 5)]
        [int]$LogLevel = 1
    )
    Begin {
        Set-StrictMode -Version latest
        $ErrorActionPreference = 'Continue'

        ########################################################################
        # Setup Logging & Globals
        ########################################################################
        if (Test-Path -Path $Path) {
            Remove-Item -Path $Path -Recurse -Force | Out-Null
        }
        New-Item -Path $Path -ItemType:Directory | Out-Null
        Set-Variable -Scope:Global -Name EKSDiag_Transcript -Value $([System.IO.Path]::Combine($Path, 'transcript.log'))
        Start-Transcript -Path $Global:EKSDiag_Transcript | Out-Null

        # Start Logging
        Set-Variable -Scope:Global -Name EKSDiag_SW         -Value $([System.Diagnostics.Stopwatch]::StartNew())
        Set-Variable -Scope:Global -Name EKSDiag_LogsDir    -Value $([System.IO.Path]::Combine($Path, 'Logs'))
        Set-Variable -Scope:Global -Name EKSDiag_Log        -Value $([System.IO.Path]::Combine($Global:EKSDiag_LogsDir, 'EKSDiag.log'))
        Set-Variable -Scope:Global -Name EKSDiag_Pester     -Value $([System.IO.Path]::Combine($Global:EKSDiag_LogsDir, 'Pester.json'))
        Set-Variable -Scope:Global -Name EKSDiag_PesterLog  -Value $([System.IO.Path]::Combine($Global:EKSDiag_LogsDir, 'Pester.log'))
        New-Item -Path $Global:EKSDiag_LogsDir -ItemType:Directory | Out-Null
        Write-Log 'Starting EKS Diag'

        # Log Levels
        Set-Variable -Scope:Global -Name EKSDiag_ObjectJsonDepth    -Value ($LogLevel * 4)
        Set-Variable -Scope:Global -Name EKSDiag_ServiceJsonDepth   -Value ($LogLevel * 2)
        Set-Variable -Scope:Global -Name EKSDiag_ExceptionJsonDepth -Value ($LogLevel * 2)

        ########################################################################
        # Prereqs
        ########################################################################

        # Add EKS to the path for referencing aws-iam-authenticator.exe
        $ENV:Path += ";$ENV:ProgramFiles/Amazon/EKS"

        # Pester
        [version]$REQUIRED_PESTER_VERSION = '4.10.1'
        Remove-Module -Name Pester -Force -ErrorAction:SilentlyContinue
        if ($null -eq (Get-Module -Name Pester -ListAvailable | Where-Object { [version]$($_.Version) -ge $REQUIRED_PESTER_VERSION })) {
            Install-Module -Name Pester -RequiredVersion $REQUIRED_PESTER_VERSION -Force -SkipPublisherCheck
        }
        Import-Module -Name Pester -RequiredVersion $REQUIRED_PESTER_VERSION -Force
        $PESTER_TEST_ROOT = $(Get-Module -Name 'amazon-eks-diag' | Select-Object -ExpandProperty ModuleBase)
    }
    Process {
        ########################################################################
        # File Based Components
        ########################################################################
        [hashtable]$fileComponents = @{
            EKSLogs       = @{
                LogDir   = [System.IO.Path]::Combine($ENV:ProgramData, 'Amazon', 'EKS', 'logs')
                LogTypes = @('*.log')
            }
            EC2LaunchLogs = @{
                LogDir   = [System.IO.Path]::Combine($ENV:ProgramData, 'Amazon', 'EC2-Windows')
                LogTypes = @('*.log')
            }
            SSMLogs       = @{
                LogDir   = [System.IO.Path]::Combine($ENV:ProgramData, 'Amazon', 'SSM')
                LogTypes = @('*.log')
                Exclude  = @('ipcTempFile.log')
            }
            CNIConfig     = @{
                LogDir   = [System.IO.Path]::Combine($ENV:ProgramData, 'Amazon', 'EKS', 'cni')
                LogTypes = @('*.conf')
            }
        }
        Write-Log 'Gathering Logs'
        Foreach ($component in $fileComponents.GetEnumerator().Name) {
            Write-Log ('[{0}] Gathering logs' -f $component)
            $params = $fileComponents[$component] + @{
                Path = $([System.IO.Path]::Combine($Global:EKSDiag_LogsDir, $component))
            }
            Get-EKSDiagLogs @params
            Write-Log ('[{0}] Completed gathering logs' -f $component)
        }
        Write-Log 'Completed: Gathering Logs'

        ########################################################################
        # Commandlet Based Components
        ########################################################################

        [hashtable]$cmdletComponents = @{
            'Get-NetAdapter'    = @(
                @{
                    Verbose = [switch]::Present
                }
            )
            'Get-NetRoute'      = @(
                @{
                    Verbose = [switch]::Present
                }
            )
            'Get-HNSNetwork'    = @(
                @{
                    Verbose = [switch]::Present
                }
            )
            'Get-HNSEndpoint'   = @(
                @{
                    Verbose = [switch]::Present
                }
            )
            'Get-HNSPolicyList' = @(
                @{
                    Verbose = [switch]::Present
                }
            )
            'Get-ScheduledTask' = @(
                @{
                    TaskName = '*EKS*'
                    Verbose  = [switch]::Present
                }
            )
            'Get-EventLog'      = @(
                @{
                    LogName = 'EKS'
                    Verbose = [switch]::Present
                }
            )
            'Get-Service'       = @(
                @{
                    Name    = 'kubelet'
                    Verbose = [switch]::Present
                },
                @{
                    Name    = 'kube-proxy'
                    Verbose = [switch]::Present
                },
                @{
                    Name    = 'docker'
                    Verbose = [switch]::Present
                },
                @{
                    Name    = 'AmazonSSMAgent'
                    Verbose = [switch]::Present
                }
            )
        }
        Write-Log 'Gathering commandlet component data'
        Foreach ($cmdlet in $cmdletComponents.GetEnumerator().Name) {
            $componentLogName = "$cmdlet.json"
            $componentLog = $([System.IO.Path]::Combine($Global:EKSDiag_LogsDir, $componentLogName))
            Write-Log ('[{0}] Gathering component data' -f $cmdlet)
            Foreach ($argSet in $cmdletComponents[$cmdlet]) {
                Write-Log ('[{0}] Args: {1}' -f $cmdlet, $argSet)
                Get-EKSDiagCmdletData -Command $cmdlet -Parameters $argSet -Path $componentLog
            }
            Write-Log ('[{0}] Completed component data' -f $cmdlet)
        }
        Write-Log 'Completed: commandlet component data'

        ########################################################################
        # Exe Based Components
        ########################################################################

        [hashtable]$exeComponents = @{
            'docker.exe'                = @(
                'ps -a',
                'images -a',
                'network ls'
            )
            'aws-iam-authenticator.exe' = @('version')
            'kubelet'                   = @('--version')
            'kube-proxy'                = @('--version')
        }
        Write-Log 'Gathering exe component data'
        Foreach ($exe in $exeComponents.GetEnumerator().Name) {
            $componentLogName = "$exe.log"
            $componentLog = $([System.IO.Path]::Combine($Global:EKSDiag_LogsDir, $componentLogName))
            Write-Log ('[{0}] Gathering exe component data' -f $exe)
            Foreach ($argSet in $exeComponents[$exe]) {
                Get-EKSDiagExeData -Command "$exe $argSet" -Path $componentLog
            }
            Write-Log ('[{0}] Completed gethering exe component data' -f $exe)
        }
        Write-Log 'Completed gathering exe component data'

        ########################################################################
        # Tests
        ########################################################################
        # - Pester
        ########################################################################

        # Execute Pester Tests
        Write-Log 'Executing tests'
        [PSCustomObject]$results = Invoke-Pester -Script $PESTER_TEST_ROOT -PassThru | Tee-Object -Append -FilePath $Global:EKSDiag_PesterLog
        Write-Log 'Completed executing tests'

        # Log Pester Results
        Write-Log 'Logging test results'
        $pesterResults = ConvertTo-Json -InputObject $results
        Out-File -FilePath $Global:EKSDiag_Pester -InputObject $pesterResults
        Write-Log 'Completed logging test results'
    }
    End {
        $Global:EKSDiag_SW.Stop()
        Write-Log 'Completed EKS Diag'
        $zip = [System.IO.Path]::Combine($ENV:Temp, "EKSDiag_$Guid.zip")
        Write-Log ('Archiving results to: {0}' -f $zip)
        Stop-Transcript | Write-Log
        Compress-Archive -Path $Path -DestinationPath $zip
        Remove-Item -Path $Path -Recurse -Force
        Write-Output (Get-Item -Path $zip)
    }
}
