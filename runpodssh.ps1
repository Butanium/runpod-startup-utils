# runpodssh.ps1
# Given a SSH connection string, update the SSH config file to add a new host entry called runpod{hostNumber}
# The host entry will be added to the SSH config file in the ~/.ssh/config file
# usage: runpodssh.ps1 'ssh_string' [host_number]
# example:
# - runpodssh.ps1 'ssh root@38.128.233.126 -p 35638'
# - runpodssh.ps1 'ssh root@38.128.89.126 -p 5987' 2
# - runpodssh.ps1 'ssh ls0vlr1zps8tmm-64411706@ssh.runpod.io -i ~/.ssh/id_ed25519'
function Convert-SshToConfig {
    param (
        [Parameter(Mandatory=$true)]
        [string]$SshString,
        
        [Parameter(Mandatory=$false)]
        [string]$HostNumber = ""
    )

    # Set host name based on HostNumber parameter
    if ($HostNumber -eq "") {
        $hostName = "runpod"
    } else {
        $hostName = "runpod$HostNumber"
    }
    
    # Remove the 'ssh' prefix if present
    $SshString = $SshString -replace '^\s*ssh\s+', ''
    
    # Remove identity file parameter if present (e.g., -i ~/.ssh/id_ed25519)
    $SshString = $SshString -replace '\s+-i\s+\S+', ''
    
    # Extract components using regex
    # Pattern supports: user@host [-p port]
    # host can be IP address or domain name
    # port is optional (defaults to 22)
    if ($SshString -match '([a-zA-Z0-9_-]+)@([a-zA-Z0-9.-]+)(?:\s+-p\s+([0-9]+))?') {
        $user = $matches[1]
        $ip = $matches[2]
        $port = if ($matches[3]) { $matches[3] } else { "22" }
        
        # Path to SSH config file
        $configPath = "$env:USERPROFILE\.ssh\config"
        
        # Check if config file exists
        if (-not (Test-Path $configPath)) {
            # Create .ssh directory if it doesn't exist
            if (-not (Test-Path "$env:USERPROFILE\.ssh")) {
                New-Item -ItemType Directory -Path "$env:USERPROFILE\.ssh" | Out-Null
            }
            # Create empty config file
            New-Item -ItemType File -Path $configPath | Out-Null
        }
        
        # Backup original config
        Copy-Item -Path $configPath -Destination "$configPath.backup" -Force
        
        # Read the config file
        $configContent = Get-Content -Path $configPath -Raw
        if ($null -eq $configContent) {
            $configContent = ""
        }
        
        # Check if Host runpod{n} section exists
        $hostPattern = [regex]::Escape($hostName)
        if ($configContent -match "Host\s+$hostPattern(\r?\n|\r)((.*?)(\r?\n|\r))*?(\s*Host\s+|\z)") {
            # Replace existing section
            $newSection = "Host $hostName`r`n   HostName $ip`r`n   User $user`r`n   Port $port`r`n   ForwardAgent yes`r`n   StrictHostKeyChecking no`r`n   UserKnownHostsFile=/dev/null`r`n"
            $configContent = $configContent -replace "Host\s+$hostPattern(\r?\n|\r)((.*?)(\r?\n|\r))*?(\s*Host\s+|\z)", "$newSection`$5"
        } else {
            # Append new section
            $newSection = "Host $hostName`r`n   HostName $ip`r`n   User $user`r`n   Port $port`r`n   ForwardAgent yes`r`n   StrictHostKeyChecking no`r`n   UserKnownHostsFile=/dev/null`r`n"
            $configContent = $configContent + "`r`n" + $newSection
        }
        
        # Write updated content back to config file
        Set-Content -Path $configPath -Value $configContent
        
        Write-Host "SSH config updated successfully for host '$hostName'!"
        Write-Host "You can now connect using: ssh $hostName"
    } else {
        Write-Host "Error: Invalid SSH string format" -ForegroundColor Red
        Write-Host "Expected format: user@hostname [-p port] [-i identity_file]"
        Write-Host "Examples:"
        Write-Host "  - 'ssh user@ip.address -p port'"
        Write-Host "  - 'ssh user@hostname -i ~/.ssh/id_ed25519'"
        Write-Host "  - 'ssh user@hostname -p port -i ~/.ssh/id_ed25519'"
        exit 1
    }
}

# Main execution logic
# Check if arguments are provided
if ($args.Count -lt 1 -or $args.Count -gt 2) {
    Write-Host "Usage: runpodssh 'ssh_string' [host_number]" -ForegroundColor Yellow
    Write-Host "Example: runpodssh 'ssh root@38.128.233.126 -p 35638'"
    Write-Host "Example with host number: runpodssh 'ssh root@38.128.233.126 -p 35638' 1"
    Write-Host "Example with identity file: runpodssh 'ssh user@ssh.runpod.io -i ~/.ssh/id_ed25519'"
    exit 1
}

# Get SSH string and optional host number
$sshString = $args[0]
$hostNumber = ""

if ($args.Count -eq 2) {
    $hostNumber = $args[1]
}

# Convert the SSH string
Convert-SshToConfig -SshString $sshString -HostNumber $hostNumber