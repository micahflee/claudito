#!/bin/bash
set -e

# Fix permissions on config directory if it's owned by root
CONFIG_DIR="/home/claudito/.config/@anthropic-ai/claude-code"
if [ -d "$CONFIG_DIR" ]; then
    # Get the owner UID of the directory
    OWNER_UID=$(ls -ldn "$CONFIG_DIR" | awk '{print $3}')
    if [ "$OWNER_UID" = "0" ]; then
        sudo chown -R claudito:claudito "$CONFIG_DIR"
    fi
fi

# Execute claude with all arguments
exec claude "$@"
