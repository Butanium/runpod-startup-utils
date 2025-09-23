#!/bin/bash

# =============================================================================
# CONFIGURATION VARIABLES - EDIT THESE BEFORE RUNNING
# =============================================================================

# Git configuration
GIT_USER_NAME="Your Name"
GIT_USER_EMAIL="your.email@example.com"

# HuggingFace token
HUGGINGFACE_TOKEN="hf_your_token_here"

# Weights & Biases API key
WANDB_API_KEY="your_wandb_api_key_here"

# OpenRouter API key
OPENROUTER_API_KEY="sk-or-v1-your_openrouter_key_here"

# Timezone (optional)
TIMEZONE="Europe/Paris"

# =============================================================================
# SETUP SCRIPT - DO NOT EDIT BELOW THIS LINE
# =============================================================================

export DEBIAN_FRONTEND=noninteractive
export TZ=$TIMEZONE

# Git configuration
git config --global credential.helper store
git config --global user.name "$GIT_USER_NAME" && git config --global user.email "$GIT_USER_EMAIL"
git config --global pull.rebase false

# Install Python packages
pip install huggingface_hub uv

# HuggingFace login
huggingface-cli login --token $HUGGINGFACE_TOKEN --add-to-git-credential

# Install system packages
apt update && apt install -y tmux nvtop htop

# Setup Weights & Biases credentials
touch ~/.netrc
if ! grep -q "machine api.wandb.ai" ~/.netrc; then
echo "machine api.wandb.ai
login user
password $WANDB_API_KEY" >> ~/.netrc
fi

# Setup bashrc with aliases and environment variables
touch ~/.bashrc
echo 'alias venv="source /root/.venv/bin/activate"' >> ~/.bashrc
echo 'export UV_PROJECT_ENVIRONMENT=/root/.venv/' >> ~/.bashrc
echo "export OPENROUTER_API_KEY=$OPENROUTER_API_KEY" >> ~/.bashrc

# Reload bashrc
source ~/.bashrc