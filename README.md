# amazon-eks-diag

`amazon-eks-diag` is a PowerShell module to help Amazon EKS users gather diagnostic information from their Amazon EC2 Windows worker nodes. The module is executed in a local PowerShell session on each worker node. The module will gather the local diagnostic information for this node only, and compresses the information into an archive. For security, the archive is left on the local file system for the system administrator to choose an apropriate mechanism for retrieving the archive.

## Usage
The module needs to be run on an EC2 Windows worker node. There are many ways of distributing the module to a node. The most straight forward is using the AWS.Tools.S3 SDK to upload the module to S3, and then download it on the node. Example:
1. Compress the `amazon-eks-diag` module directory, and write the archive to S3
```powershell
Compress-Archive -Path .\amazon-eks-diag\ -DestinationPath .\amazon-eks-diag.zip
Write-S3Object -BucketName my-bucket -Key modules/amazon-eks-diag.zip -File .\amazon-eks-diag.zip
```
2. On your node, download the archive and extract it
```powershell
Read-S3Object -BucketName my-bucket -Key modules/amazon-eks-diag.zip -File .\amazon-eks-diag.zip
Expand-Archive -Path .\amazon-eks-diag.zip -DestinationPath .\
```
3. Open a powershell session with the appropriate elevation, import the module, and execute the diagnostic tool
```powershell
Import-Module .\amazon-eks-diag
$outputZip = Start-EKSDiag
```
## Diagnostic Information Gathered
Following is a categorical overview of the diagnostic information gathered by the tool in the way the data is gathered by the tool:
1. EKS & EC2 Windows related log and configuration files
    * $ENV:ProgramData\Amazon\EKS\logs\\**\\*.log
    * $ENV:ProgramData\Amazon\EKS\cni\\**\\*.config
    * $ENV:ProgramData\Amazon\EC2-Windows\\**\\*.log
    * $ENV:ProgramData\Amazon\SSM\\**\\*.log `(Excluding ipcTempFeil.log from SSM Session Manager)`
2. Related PowerShell objects serialized into JSON
    * Get-NetAdapter
    * Get-NetRoute
    * Get-HNSNetwork
    * Get-HNSEndpoint
    * Get-HNSPolicyList
    * Get-ScheduledTask -TaskName '\*EKS\*'
    * Get-EventLog -LogName 'EKS'
    * Get-Service -Name 'kubelet'
    * Get-Service -Name 'kube-proxy'
    * Get-Service -Name 'docker'
    * Get-Service -Name 'AmazonSSMAgent'
3. Related executable output
    * docker ps -a
    * docker images -a
    * docker network ls
4. Pester test output from the tests stored within the local module
    * amazon-eks-diag.hns.tests.ps1
    * amazon-eks-diag.kubeproxy.tests.ps1
    * amazon-eks-diag.kubelet.tests.ps1
5. A PowerShell transcript of the entire tool execution for transparency

## Help

```powershell
Get-Help Start-EKSDiag -Full
```

## Unit Testing

```powershell
Install-Module Pester -Repository PSGallery -SkipPublisherCheck -Force
.\Start-UnitTests.ps1
```

## License

This project is licensed under the Apache-2.0 License.
