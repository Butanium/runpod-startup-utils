# RunPod Tutorial Scripts

This repository contains utility scripts for managing RunPod instances and SSH connections.

## Files Overview

### `startup_runpod_template.sh` (Startup Template)
A template script for initializing RunPod instances with common development tools and configurations.

**Features:**
- Git configuration setup
- HuggingFace CLI integration with token login
- Weights & Biases (wandb) API key configuration
- OpenRouter API key setup
- System package installation (tmux, nvtop, htop)
- Python environment configuration with UV package manager
- Timezone configuration
- Useful bash aliases and environment variables

**Configuration Required:**
Before running, edit the configuration variables at the top of the script:
- `GIT_USER_NAME`: Your Git username
- `GIT_USER_EMAIL`: Your Git email
- `HUGGINGFACE_TOKEN`: Your HuggingFace access token
- `WANDB_API_KEY`: Your Weights & Biases API key
- `OPENROUTER_API_KEY`: Your OpenRouter API key
- `TIMEZONE`: Your preferred timezone (default: Europe/Paris)

**Usage:**
```bash
# Make executable and run
chmod +x startup_runpod_template.sh
./startup_runpod_template.sh
```

### `runpodssh.ps1` (PowerShell Script)
A PowerShell script that simplifies SSH configuration for RunPod instances by automatically parsing SSH connection strings and adding them to your SSH config file.

**Features:**
- Parses RunPod SSH connection strings in various formats
- Supports both IP addresses and domain names (e.g., `ssh.runpod.io`)
- Handles optional port parameter (defaults to 22)
- Automatically strips identity file parameters (`-i` flag)
- Automatically adds/updates SSH host entries in `~/.ssh/config`
- Supports custom host numbering (e.g., `runpod1`, `runpod2`)
- Creates backup of existing SSH config before modifications
- Includes security settings like `StrictHostKeyChecking no` for convenience

**Usage:**
```powershell
# Basic usage with IP and port (creates host named "runpod")
.\runpodssh.ps1 'ssh root@38.128.233.126 -p 35638'

# With custom host number (creates host named "runpod2")
.\runpodssh.ps1 'ssh root@38.128.89.126 -p 5987' 2

# With domain name and identity file (identity file is dropped)
.\runpodssh.ps1 'ssh ls0vlr1zps8tmm-64411706@ssh.runpod.io -i ~/.ssh/id_ed25519'

# Without port (defaults to port 22)
.\runpodssh.ps1 'ssh user@hostname.com'
```

**Requirements:** Windows PowerShell

### `runpodssh.sh` (Bash Script)
A Bash port of the PowerShell script with equivalent functionality for Unix-like systems.

**⚠️ Important Note:** This script is a direct conversion from PowerShell using GPT-5-high assistance and **has NOT been tested**. Use with caution and verify functionality before relying on it in production environments.

**Features:**
- Same functionality as the PowerShell version
- Uses AWK for advanced text processing
- Maintains SSH config file permissions (600 for config, 700 for .ssh directory)
- Robust error handling with `set -euo pipefail`

**Usage:**
```bash
# Basic usage (creates host named "runpod")
./runpodssh.sh 'ssh root@38.128.233.126 -p 35638'

# With custom host number (creates host named "runpod2")
./runpodssh.sh 'ssh root@38.128.89.126 -p 5987' 2
```

**Requirements:** Bash shell, AWK


## Quick Start

1. **For SSH Configuration:**
   - Windows: Use `runpodssh.ps1`
   - Linux/Mac: Use `runpodssh.sh` (test carefully first!)

2. **For RunPod Instance Setup:**
   - Edit `startup_runpod_template.sh` with your credentials
   - Run the script on your new RunPod instance

## Contributing

If you test the `runpodssh.sh` script and find issues, please report them or submit fixes.
