#!/bin/bash

# Configuration
DOTFILES_DIR="$HOME/dotfiles"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

set -e

# make sure .config exists
if [ ! -d "$DOTFILES_DIR/.config" ]; then
    echo "Error: $DOTFILES_DIR/.config does not exist in the repository!"
    exit 1
fi

# create ~/.config if it doesn't exist
if [ ! -d "$CONFIG_DIR" ]; then
    echo "Creating $CONFIG_DIR..."
    mkdir -p "$CONFIG_DIR"
fi

# backup existing files in ~/.config
if [ -n "$(ls -A "$CONFIG_DIR")" ]; then
    echo "Backing up existing $CONFIG_DIR to $BACKUP_DIR..."
    mkdir -p "$BACKUP_DIR"
    cp -r "$CONFIG_DIR"/* "$BACKUP_DIR" 2>/dev/null || true
fi

# create symlinks for each file/directory in dotfiles/.config
echo "Creating symlinks from $DOTFILES_DIR/.config to $CONFIG_DIR..."
for item in "$DOTFILES_DIR/.config"/*; do
    if [ -e "$item" ]; then
        item_name=$(basename "$item")
        target="$CONFIG_DIR/$item_name"
        source="$DOTFILES_DIR/.config/$item_name"

        # Remove existing file/dir at target if it’s not a symlink
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            echo "Removing existing $target (backed up to $BACKUP_DIR)..."
            rm -rf "$target"
        fi

        # Create the symlink
        if [ ! -e "$target" ] || [ -L "$target" ]; then
            ln -sf "$source" "$target"
            echo "Linked: $target -> $source"
        fi
    fi
done

echo "Dotfiles setup complete! Symlinks created in $CONFIG_DIR."
echo "Backup of original config (if any) is in $BACKUP_DIR."
