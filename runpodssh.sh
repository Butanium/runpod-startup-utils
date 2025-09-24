#!/bin/bash

# Function to convert SSH command to config format
convert_ssh_to_config() {
    local ssh_string="$1"
    local host_name="runpod"  # Default host name

    # Extract components using regex
    if [[ $ssh_string =~ ([a-zA-Z0-9_-]+)@([0-9.]+)[[:space:]]+-p[[:space:]]+([0-9]+) ]]; then
        local user="${BASH_REMATCH[1]}"
        local ip="${BASH_REMATCH[2]}"
        local port="${BASH_REMATCH[3]}"

        # Create temporary file
        local temp_file=$(mktemp)
        
        # Process the config file
        awk -v ip="$ip" -v user="$user" -v port="$port" '
            BEGIN { in_runpod = 0; printed = 0 }
            /^Host runpod$/ {
                in_runpod = 1
                print $0
                next
            }
            in_runpod && /^Host / {
                if (!printed) print ""
                in_runpod = 0
            }
            in_runpod {
                if ($1 == "HostName") print "   HostName", ip
                else if ($1 == "User") print "   User", user
                else if ($1 == "Port") print "   Port", port
                else print $0
                next
            }
            { print }
            END {
                if (in_runpod && !printed) print ""
            }
        ' ~/.ssh/config > "$temp_file"

        # Backup original config
        cp ~/.ssh/config ~/.ssh/config.backup
        
        # Move temporary file to config
        cat "$temp_file" > ~/.ssh/config
        rm "$temp_file"
        
        # Minimal patch: append Host runpod block if missing
        if ! grep -Eq '^Host[[:space:]]+runpod$' ~/.ssh/config; then
          {
            echo ""
            echo "Host runpod"
            echo "    HostName $ip"
            echo "    User $user"
            echo "    Port $port"
          } >> ~/.ssh/config
          echo "Added new Host runpod block."
        else
          echo "Updated existing Host runpod block."
        fi
    else
        echo "Error: Invalid SSH string format"
        exit 1
    fi
}

# Check if argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 'ssh_string'"
    echo "Example: $0 'ssh root@38.128.233.126 -p 35638'"
    exit 1
fi

# Convert the SSH string
convert_ssh_to_config "$1"