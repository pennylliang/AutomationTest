param(
    [string]$VmName,
    [string]$TargetRGName,
    [string]$ParameterFile,
    [string]$BuildId
)

# incase we call this script from Jenkins (Ant) directly
if(!$VmName -and $ParameterFile -and $BuildId) {
    $Params = (get-content $ParameterFile) -join "`n" | ConvertFrom-Json
    $VmName = $Params.vmName.value + $BuildId
    $TargetRGName = $Params.resourceGroup.value
}

# Get VM Object
$VM = Get-AzureRmVM -ResourceGroupName $TargetRGName -Name $VmName
# Get NetworkInterface name
$NicName = $vm.NetworkProfile.NetworkInterfaces.id.split("/")[-1]
# Get Public IP name, Storage account name
$PublicIP = (Get-AzureRmNetworkInterface -ResourceGroupName $TargetRGName -Name $nicname).IpConfigurations.publicipaddress.id.split("/")[-1]
$StorageName = $vm.StorageProfile.osdisk.vhd.uri.replace("http://","").split(".")[0]

Write-Host "Removing vm"
#Stop-AzureRmVM -ResourceGroupName $TargetRGName -Name MyWindowsVM -Force
Remove-AzureRmVM -ResourceGroupName $TargetRGName -Name $VmName -Force
Write-Host "Removing Network interface"
Remove-AzureRmNetworkInterface -ResourceGroupName $TargetRGName -Name $NicName -Force
Write-Host "Removing Public IP"
Remove-AzureRmPublicIpAddress -ResourceGroupName $TargetRGName -Name $PublicIP -Force
Write-Host "Removing Storage Account"
Remove-AzureRmStorageAccount -ResourceGroupName $TargetRGName -Name $StorageName 
