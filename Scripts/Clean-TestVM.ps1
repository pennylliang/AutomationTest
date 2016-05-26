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

$Params = (get-content $ParameterFile) -join "`n" | ConvertFrom-Json
$VmName = $Params.vmName.value + $BuildId
$TargetRGName = $Params.resourceGroup.value

Clean-VM -vmName $VmName -TargetRGName $TargetRGName

