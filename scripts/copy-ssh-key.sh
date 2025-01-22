#!/usr/bin/env bash

# Check if SSH key exists
if [ ! -f "$HOME/.ssh/id_rsa.pub" ]; then
    echo "Error: SSH public key not found at $HOME/.ssh/id_rsa.pub"
    echo "Generate one first using: ssh-keygen -t rsa -b 4096"
    exit 1
fi

# Check if required arguments are provided
if [ $# -lt 2 ]; then
    echo "Usage: $0 <remote_user> <remote_host> [remote_port]"
    echo "Example: $0 john example.com 22"
    exit 1
fi

REMOTE_USER="$1"
REMOTE_HOST="$2"
REMOTE_PORT="${3:-22}"  # Default to port 22 if not specified

# Create .ssh directory on remote host and set permissions
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" '
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
'

# Copy the public key
cat "$HOME/.ssh/id_rsa.pub" | ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" '
    cat >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
'

# Check if the copy was successful
if [ $? -eq 0 ]; then
    echo "SSH key successfully copied to $REMOTE_USER@$REMOTE_HOST"
    echo "You should now be able to SSH without a password"
else
    echo "Error: Failed to copy SSH key"
    exit 1
fi
