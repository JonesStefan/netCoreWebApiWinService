# From Asp.netCore.Docs GitHub 
# https://github.com/aspnet/AspNetCore.Docs/blob/master/aspnetcore/host-and-deploy/windows-service/scripts/2.x/RegisterService.ps1
#Requires -Version 6.2
#Requires -RunAsAdministrator

param(
    [Parameter(mandatory=$true)]
    [string]
    $Name,
    [Parameter(mandatory=$true)]
    [string]
    $DisplayName,
    [Parameter(mandatory=$true)]
    [string]
    $Description,
    [Parameter(mandatory=$true)]
    [System.IO.FileInfo]
    $Exe,
    [Parameter(mandatory=$true)]
    [string]
    $User
)

$acl = Get-Acl $($Exe.DirectoryName)
$aclRuleArgs = $User, "Read,Write,ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($aclRuleArgs)
$acl.SetAccessRule($accessRule)
$acl | Set-Acl $($Exe.DirectoryName)

New-Service -Name $Name -BinaryPathName $($Exe.FullName) -Credential $User -Description $Description -DisplayName $DisplayName -StartupType Automatic