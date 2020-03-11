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
This is a pester test file used for validating the HNS configuration
#>
Describe "HNS" {
    Context "General" {
        It "can describe the HNS network" {
            { Get-HnsNetwork } | Should Not Throw
        }
    }
    Context "DHCP" {
        It "does not have DHCP global broadcast set" {
            $DhcpGlobalForceBroadcastFlag = "HKLM:\SYSTEM\CurrentControlSet\Services\Dhcp\Parameters\DhcpGlobalForceBroadcastFlag"
            Test-Path -Path $DhcpGlobalForceBroadcastFlag | Should Be $false
        }
    }
    Context "L2Bridge" {
        It "has the L2Bridge" {
            Get-HnsNetwork | Where-Object { $_.type -eq "L2Bridge" } | Should Not Be $null
        }
        It "bridge is active" {
            $bridge = Get-HnsNetwork | Where-Object { $_.type -eq "L2Bridge" }

            $bridge.State | Should Be 1
        }
    }
}