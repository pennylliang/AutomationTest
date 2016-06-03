param(
    [string]$Computer,
    [string]$Username,
    [string]$Password,
    [string]$Command
)

$Secpass = ConvertTo-secureString $Password -asPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential ($Username,$Secpass)
$wfs = New-PSSession -ComputerName $Computer -Credential $Cred
if(!$wfs) {
    write-host "Fail to new a PS Session to computer $Computer"
    exit 1
}

$TestJob = Invoke-Command -AsJob -JobName "AutoTest" -Session $wfs  -ScriptBlock {
    param ($Cmd)
    write-host "----$Cmd----"
    Start-Sleep -s 60
} -ArgumentList $Command

Wait-Job $TestJob
$Result = Receive-Job $TestJob
write-host $Result

exit 0
