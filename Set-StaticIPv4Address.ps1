#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Interactively sets a static IPv4 address, gateway, and DNS for a Windows adapter.
.DESCRIPTION
Uses a /24 subnet. Enter the last octet for addresses that share the new IP's
first three octets, or enter a full address. DNS can be on a different subnet.
Run from an elevated PowerShell console on the machine or VM being configured.
#>

$ErrorActionPreference = 'Stop'

function Read-IPv4Address {
    param([string]$Prompt, [string]$Prefix, [switch]$Optional)

    while ($true) {
        $value = (Read-Host $Prompt).Trim()
        if ($Optional -and $value -eq '') { return }

        if ($Prefix -and $value -match '^[0-9]{1,3}$') {
            $value = "$Prefix.$value"
        }

        if ($value -match '^[0-9]{1,3}(\.[0-9]{1,3}){3}$') {
            $octets = @($value.Split('.') | ForEach-Object { [int]$_ })
            if (($octets | Measure-Object -Maximum).Maximum -le 255) {
                return ($octets -join '.')
            }
        }

        Write-Host 'Enter a valid IPv4 address.' -ForegroundColor Yellow
    }
}

function Invoke-IPv4Netsh {
    param([string[]]$Arguments)

    & netsh.exe interface ipv4 @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "netsh failed running '$($Arguments -join ' ')'. Check the adapter's current settings before retrying."
    }
}

$adapters = @(Get-NetAdapter | Sort-Object Name)
if ($adapters.Count -eq 0) { throw 'No network adapters were found.' }

for ($i = 0; $i -lt $adapters.Count; $i++) {
    $adapter = $adapters[$i]
    $addresses = @(Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        ForEach-Object { "$($_.IPAddress)/$($_.PrefixLength)" })

    Write-Host ('{0}. {1} [{2}] {3}' -f ($i + 1), $adapter.Name, $adapter.Status, ($addresses -join ', '))
}

do {
    $choice = 0
    $inputValue = Read-Host 'Enter the adapter number, or Q to quit'
    if ($inputValue.Trim() -eq 'Q') { return }
} until ([int]::TryParse($inputValue, [ref]$choice) -and
         $choice -ge 1 -and $choice -le $adapters.Count)

$adapter = $adapters[$choice - 1]

do {
    $ip = Read-IPv4Address 'New static IPv4 address'
    $prefix = $ip.Substring(0, $ip.LastIndexOf('.'))
    $hostOctet = [int]($ip.Split('.')[-1])

    if ($hostOctet -in 0, 255) {
        Write-Host 'For a /24 network, the IP must end in 1 through 254.' -ForegroundColor Yellow
    }
} until ($hostOctet -notin 0, 255)

do {
    $gateway = Read-IPv4Address "Gateway for $prefix.x (last octet or full IPv4 address)" -Prefix $prefix
    $gatewayOctet = [int]($gateway.Split('.')[-1])
    $validGateway = $gateway.StartsWith("$prefix.") -and
                    $gatewayOctet -notin 0, 255 -and $gateway -ne $ip

    if (-not $validGateway) {
        Write-Host "Use a different host address on $prefix.0/24." -ForegroundColor Yellow
    }
} until ($validGateway)

$dns1 = Read-IPv4Address 'Preferred DNS (last octet if on the same subnet, or full IPv4 address)' -Prefix $prefix

do {
    $dns2 = Read-IPv4Address 'Alternate DNS (last octet, full IPv4 address, or Enter for none)' -Prefix $prefix -Optional
    if ($dns2 -eq $dns1) {
        Write-Host 'Enter a different alternate DNS server or leave it blank.' -ForegroundColor Yellow
    }
} until ($dns2 -ne $dns1)

Write-Host ''
Write-Host "Adapter       $($adapter.Name)"
Write-Host "IPv4 address  $ip/24"
Write-Host "Gateway       $gateway"
Write-Host "Preferred DNS $dns1"
Write-Host "Alternate DNS $dns2"
Write-Host ''
Write-Host "This replaces the adapter's existing IPv4 addresses, default gateway, and IPv4 DNS settings."
if ((Read-Host 'Type YES to apply').Trim() -ne 'YES') { return }

$interface = "name=$($adapter.ifIndex)"

Invoke-IPv4Netsh -Arguments @(
    'set', 'address', $interface, 'source=static', "address=$ip",
    'mask=255.255.255.0', "gateway=$gateway", 'store=persistent'
)

Invoke-IPv4Netsh -Arguments @(
    'set', 'dnsservers', $interface, 'source=static', "address=$dns1", 'validate=no'
)

if ($dns2) {
    Invoke-IPv4Netsh -Arguments @(
        'add', 'dnsservers', $interface, "address=$dns2", 'index=2', 'validate=no'
    )
}

Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex
