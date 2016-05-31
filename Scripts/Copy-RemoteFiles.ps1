param(
    [string]$Source,
    [string]$Destination,
    [string]$Username,
    [string]$Password
)

$MaxRetry = 3

write-host "$Source    $Destination     $Username    $Password"
# Get the remote address from $Source or $Destination
if($Source -like "\\*") {
    $Address = $Source
} elseif($Destination -like "\\*") {
    $Address = $Destination
} else {
    write-host "It's not a remote copy. Source: $Source; Destination: $Destination"
    exit 1
}

# incase the path is a file, "net use" only accept folder path
# like: \\spotlighttestvm42.westus.cloudapp.azure.com\c$
$Res = net use "$Address" $Password /USER:$Username
if(!$Res) {
    $Pos = $Address.lastindexof("\")
    $Address = $Address.substring(0,$Pos)
    $Res = net use $Address $Password /USER:$Username
    if(!$Res) {
        write-host "Fail to setup network connection to $Address"
        exit 2
    }
}

$Retry = 0
while ($Retry -lt $MaxRetry) {
    Copy-Item "$Source" -Destination "$Destination" -recurse
    if($? -eq $true) {
        break
    }
    write-host "Fail to copy file from $Source to $Destination, $Retry times"
    $Retry++
}

net use $Address /delete

if($Retry -eq $MaxRetry) {
    write-host "Fail to copy file after retry $Retry times"
    exit 3
}

exit 0
