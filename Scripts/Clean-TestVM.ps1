param(
    [string]$ParameterFile,
    [string]$BuildId
)

. .\DeployUtilities.ps1

$res = Login-AutomationAzure
if($res -ne 0) {
    write-host ("Fail to login Azure.")
    exit 1 
}

Clean-VM -vmName $vmName -TargetRGName $TargetRGName

