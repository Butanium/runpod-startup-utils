#!/usr/bin/env bash
# Given a SSH connection string, update the SSH config file to add a new host entry called runpod{hostNumber}
# The host entry will be added to the SSH config file in the ~/.ssh/config file
# usage: runpodssh.ps1 'ssh_string' [host_number]
# example:
# - runpodssh.ps1 'ssh root@38.128.233.126 -p 35638'
# - runpodssh.ps1 'ssh root@38.128.89.126 -p 5987' 2
# Converted from my runpodssh.ps1 script with the courtesy of gpt-5-high AND NOT TESTED

set -euo pipefail

script_name="$(basename "$0")"

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Usage: $script_name 'ssh_string' [host_number]" >&2
    echo "Example: $script_name 'ssh root@38.128.233.126 -p 35638'" >&2
    echo "Example with host number: $script_name 'ssh root@38.128.233.126 -p 35638' 2" >&2
    exit 1
fi

ssh_string="$1"
host_number="${2:-}"

if [ -z "${host_number}" ]; then
    host_name="runpod"
else
    host_name="runpod${host_number}"
fi

# Parse SSH string: match "username@ip -p port" anywhere (like the PowerShell script)
regex='([A-Za-z0-9_-]+)@([0-9.]+)[[:space:]]+-p[[:space:]]+([0-9]+)'
if [[ "$ssh_string" =~ $regex ]]; then
    user="${BASH_REMATCH[1]}"
    ip="${BASH_REMATCH[2]}"
    port="${BASH_REMATCH[3]}"
else
    echo "Error: Invalid SSH string format" >&2
    echo "Expected format: username@ip.address -p port" >&2
    exit 1
fi

config_dir="${HOME}/.ssh"
config_path="${config_dir}/config"

# Ensure .ssh exists and config file is present with secure permissions
mkdir -p "$config_dir"
chmod 700 "$config_dir"
touch "$config_path"
chmod 600 "$config_path"

# Backup original config
cp -f "$config_path" "${config_path}.backup"

# Build new host section (three leading spaces for each directive)
new_section=$(cat <<EOF
Host ${host_name}
   HostName ${ip}
   User ${user}
   Port ${port}
   ForwardAgent yes
   StrictHostKeyChecking no
   UserKnownHostsFile=/dev/null
EOF
)

# Replace existing Host block or append new one
tmp_path="${config_path}.tmp.$$"
awk -v host="${host_name}" -v block="${new_section}" '
BEGIN {
    replaced = 0
    in_target = 0
}

# If we encounter any Host line while skipping the old target block, end skipping before processing the line
/^[[:space:]]*Host[[:space:]]+[[:graph:]]+/ {
    if (in_target == 1) {
        in_target = 0
    }
}

{
    # Detect the start of the target host block
    if ($0 ~ "^[[:space:]]*Host[[:space:]]+" host "[[:space:]]*$") {
        if (replaced == 0) {
            print block
            replaced = 1
        }
        in_target = 1
        next
    }

    if (in_target == 1) {
        # Skip lines inside the old target block until the next Host line
        if ($0 ~ "^[[:space:]]*Host[[:space:]]+[[:graph:]]+") {
            in_target = 0
            print
        }
        next
    }

    print
}

END {
    if (replaced == 0) {
        if (NR > 0) {
            print ""
        }
        print block
    }
}
' "$config_path" > "$tmp_path"

mv "$tmp_path" "$config_path"

echo "SSH config updated successfully for host '${host_name}'!"
echo "You can now connect using: ssh ${host_name}"

