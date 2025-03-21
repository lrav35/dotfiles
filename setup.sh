#!/bin/bash

# Configuration
DOTFILES_DIR="$HOME/dotfiles"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

set -e

# check if an argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <all|package_name>"
    echo "Example: $0 all  # Symlink all packages"
    echo "Example: $0 hypr # Symlink only hypr"
    exit 1
fi

MODE="$1"  # 'all' or specific package name (e.g., 'hypr')

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
if [ "$MODE" = "all" ] && [ -n "$(ls -A "$CONFIG_DIR")" ]; then
    echo "Backing up existing $CONFIG_DIR to $BACKUP_DIR..."
    mkdir -p "$BACKUP_DIR"
    cp -r "$CONFIG_DIR"/* "$BACKUP_DIR" 2>/dev/null || true
elif [ "$MODE" != "all" ] && [ -e "$CONFIG_DIR/$MODE" ]; then
    echo "Backing up existing $CONFIG_DIR/$MODE to $BACKUP_DIR..."
    mkdir -p "$BACKUP_DIR"
    cp -r "$CONFIG_DIR/$MODE" "$BACKUP_DIR" 2>/dev/null || true
fi

# Function to create a symlink for a single item
create_symlink() {
    local source="$1"
    local target="$2"
    local item_name=$(basename "$source")

    # Remove existing file/dir at target if it’s not a symlink
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo "Removing existing $target (backed up to $BACKUP_DIR)..."
        rm -rf "$target"
    fi

    # Create the symlink only if it doesn’t exist
    if [ ! -e "$target" ]; then
        ln -s "$source" "$target"
        echo "Linked: $target -> $source"
    else
        echo "Skipped: $target already exists"
    fi
}

# Create symlinks based on the mode
echo "Creating symlinks from $DOTFILES_DIR/.config to $CONFIG_DIR..."
if [ "$MODE" = "all" ]; then
    # Symlink all items in dotfiles/.config
    for item in "$DOTFILES_DIR/.config"/*; do
        if [ -e "$item" ]; then
            item_name=$(basename "$item")
            target="$CONFIG_DIR/$item_name"
            source="$DOTFILES_DIR/.config/$item_name"
            create_symlink "$source" "$target"
        fi
    done
else
    # Symlink only the specified package
    source="$DOTFILES_DIR/.config/$MODE"
    target="$CONFIG_DIR/$MODE"
    if [ -e "$source" ]; then
        create_symlink "$source" "$target"
    else
        echo "Error: $source does not exist in $DOTFILES_DIR/.config!"
        exit 1
    fi
fi

echo "Dotfiles setup complete!"
if [ -d "$BACKUP_DIR" ]; then
    echo "Backup of original config (if any) is in $BACKUP_DIR."
fi
