param(
    [string]$ParameterFile=$(throw "missing parameter -ParameterFile Parameter JSON File"),
    [string]$TemplateFile=$(throw "missing parameter -TemplateFile path to store the template file"),
    [string]$BuildId=$(throw "missing parameter -BuildId build id from jenkins")
)

##############    Begin to Login Azure     ##################
$Password = "Quest123"
$Username = "086de0c4-792c-462f-b333-818c6c5f8078"
$SecurePassword = ConvertTo-SecureString -string $Password -AsPlainText –Force
$Cred = new-object System.Management.Automation.PSCredential ($Username, $SecurePassword)
$TenantId = "91c369b5-1c9e-439c-989c-1867ec606603"
Login-AzureRmAccount -Credential $cred -ServicePrincipal -TenantId $TenantId

############## Check/Create Resource Group ##################
write-host "parameter file: $ParameterFile"
write-host "template file: $TemplateFile"
$Params = (get-content $ParameterFile) -join "`n" | ConvertFrom-Json

$ParamHashTable = @{}

$ParamHashTable.adminUsername = $Params.adminUsername.value
$ParamHashTable.adminPassword = $Params.adminPassword.value
$ParamHashTable.dnsNameForPublicIP = $Params.dnsNameForPublicIP.value + $BuildId 
$ParamHashTable.virtualNetworkName = $Params.virtualNetworkName.value
$ParamHashTable.subnetName = $Params.subnetName.value
$ParamHashTable.vmName = $Params.vmName.value + $BuildId 
$ParamHashTable.virtualNetworkResourceGroup = $Params.virtualNetworkResourceGroup.value 

write-host "Parameter Hash Table:"
$ParamHashTable

$vmName = $ParamHashTable.vmName
$TargetRGName = $Params.resourceGroup.value
$MaxRetryDeployVM = 3
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
            break 
        } else {
            write-host($DeployCommand | Out-String)
            throw $error[0].exception
        }
    } catch {
        Write-host "Fail to deploy template"
        &  C:\scripts\CleanTestVM.ps1 -vmName $vmName -TargetRGName $TargetRGName 
    }
    $Retry++
}


if ($Retry -eq $MaxRetryDeployVM) {
    write-host ("Fail to deploy template after retry $Retry times")
    exit 1 
}

if ($DeployCommand.ProvisioningState -eq "Succeeded") {
    exit 0
} else {
    exit 2
}

