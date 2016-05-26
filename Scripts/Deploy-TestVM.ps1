param(
    [string]$ParameterFile=$(throw "missing parameter -ParameterFile Parameter JSON File"),
    [string]$TemplateFile=$(throw "missing parameter -TemplateFile path to store the template file"),
    [string]$BuildId=$(throw "missing parameter -BuildId build id from jenkins")
)

. .\DeployUtilities.ps1

$res = Login-AutomationAzure
if($res -ne 0) {
    write-host ("Fail to login Azure.")
    exit 1 
}

############## Check/Create Resource Group ##################
write-host "parameter file: $ParameterFile"
write-host "template file: $TemplateFile"
$Params = (get-content $ParameterFile) -join "`n" | ConvertFrom-Json

$ParamHashTable = @{}

$ParamHashTable.adminUsername = $Params.adminUsername.value
$ParamHashTable.adminPassword = $Params.adminPassword.value
$ParamHashTable.dnsNameForPublicIP = $Params.dnsNamePrefix.value + $BuildId 
$ParamHashTable.virtualNetworkName = $Params.virtualNetworkName.value
$ParamHashTable.subnetName = $Params.subnetName.value
$ParamHashTable.vmName = $Params.vmNamePrefix.value + $BuildId 
$ParamHashTable.virtualNetworkResourceGroup = $Params.virtualNetworkResourceGroup.value 

write-host "Parameter Hash Table:"
$ParamHashTable

$vmName = $ParamHashTable.vmName
$TargetRGName = $Params.resourceGroup.value
$MaxRetryDeployVM = 1
$Retry = 0

##############     Deploy Test VM          ##################
While ($Retry -lt $MaxRetryDeployVM) {
    $times = $Retry + 1 
    Write-Host "This is the $times time to deploy"
      
    try {
        $DeploymentName = "TestVM{0}" -f (Get-Date -Format 'yyyyMMddHHmmss')
        $DeployCommand = New-AzureRMResourceGroupDeployment -Name $DeploymentName `
                                                 -ResourceGroupName $TargetRGName `
                                                 -TemplateFile $TemplateFile `
                                                 -TemplateParameterObject $ParamHashTable `

        if ($DeployCommand.ProvisioningState -eq "Succeeded") {
            Write-Host "Deploy template successfully"
            exit 0 
        } else {
            write-host($DeployCommand | Out-String)
        }
    } catch {
        Write-host "Fail to deploy template"
    }
    Clean-VM -vmName $vmName -TargetRGName $TargetRGName 
    $Retry++
}


if ($Retry -eq $MaxRetryDeployVM) {
    write-host ("Fail to deploy template after retry $Retry times")
    exit 2 
}

# Unknown
exit 3

