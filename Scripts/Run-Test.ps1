param(
    [string]$Computer,
    [string]$Username,
    [string]$Password,
    [string]$Command
)

write-host "Connecting to $Computer as $Username, run command $Command"
# since our Test VM and QA VM (jenkins slave) are in different domain
# have to add the test VM to trusted host list, otherwise New-PSSession
# will fail.
write-host "Setting $Computer to WSMan:\localhost\Client\TrustedHosts"
Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value "$Computer" -Force
get-item -Path WSMan:\localhost\Client\TrustedHosts

$Secpass = ConvertTo-secureString $Password -asPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential ($Username,$Secpass)
$wfs = New-PSSession -ComputerName $Computer -Credential $Cred
if(!$wfs) {
    write-host "Fail to new a PS Session to computer $Computer"
    exit 1
}

# If the job uses Write-Host to produce output, Receive-Job returns $null,
# but the results get written to the host. However, if the job uses Write-Output
# to produce output in lieu of Write-Host, Receive-Job returns a string 
# array [string[]] of the job output. so use write-output in the remote Job
$TestJob = Invoke-Command -AsJob -JobName "AutoTest" -Session $wfs  -ScriptBlock {
    param ($Cmd)
    write-Output "----$Cmd----"
    Start-Sleep -s 60
} -ArgumentList $Command

Wait-Job $TestJob
$TestResult = Receive-Job $TestJob
write-host $TestResult

exit 0
