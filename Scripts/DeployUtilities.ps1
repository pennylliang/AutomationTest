<#
.SYNOPSIS
Login Automation Test Azure account

.DESCRIPTION
return value:
0 : success
1 : fail

#>
function Login-AutomationAzure {
    write-host "Loging in Azure account..."
    $Password = "Quest123"
    $Username = "086de0c4-792c-462f-b333-818c6c5f8078"
    $SecurePassword = ConvertTo-SecureString -string $Password -AsPlainText -Force
    $Cred = new-object System.Management.Automation.PSCredential ($Username, $SecurePassword)
    $TenantId = "91c369b5-1c9e-439c-989c-1867ec606603"
    $res = Login-AzureRmAccount -Credential $cred -ServicePrincipal -TenantId $TenantId
    if(!$res) {
        write-host "Auto Login fail!"
        return 1
    }
    return 0
}

<#
.SYNOPSIS
Remove VM and all its related resource 
(Network Interface/Public IP/Storage account)

.DESCRIPTION
ignore the remove result currently
TODO: Now only assume VM has only one network interface,
one Public IP, and VHD in a new storage account. Need
to enhance to work for different cases later.
Also need to check the command result and give re-try if
needed.

.PARAMETER TargetRGName
Resource group the VM belongs to.
.PARAMETER VmName
VM name
#>
function Clean-VM {
    param([String]$TargetRGName, [String]$VmName)

    Write-Host "Going to remove $VmName from $TargetRGName"
    # Get VM Object
    $VM = Get-AzureRmVM -ResourceGroupName $TargetRGName -Name $VmName
    if(!$VM) {
       return 0
    }
    # Get NetworkInterface name
    $NicName = $vm.NetworkProfile.NetworkInterfaces.id.split("/")[-1]
    # Get Public IP name 
    $PublicIP = (Get-AzureRmNetworkInterface -ResourceGroupName $TargetRGName -Name $nicname).IpConfigurations.publicipaddress
    if($PublicIP) {
        $PublicIP = (Get-AzureRmNetworkInterface -ResourceGroupName $TargetRGName -Name $nicname).IpConfigurations.publicipaddress.id.split("/")[-1]
    }
    # Storage account name
    $StorageName = $vm.StorageProfile.osdisk.vhd.uri.replace("http://","").split(".")[0]
    
    Write-Host "Removing vm"
    #Stop-AzureRmVM -ResourceGroupName $TargetRGName -Name MyWindowsVM -Force
    Remove-AzureRmVM -ResourceGroupName $TargetRGName -Name $VmName -Force
    Write-Host "Removing Network interface"
    Remove-AzureRmNetworkInterface -ResourceGroupName $TargetRGName -Name $NicName -Force
    if($PublicIP) {
        Write-Host "Removing Public IP"
        Remove-AzureRmPublicIpAddress -ResourceGroupName $TargetRGName -Name $PublicIP -Force
    }
    Write-Host "Removing Storage Account"
    Remove-AzureRmStorageAccount -ResourceGroupName $TargetRGName -Name $StorageName 
}
