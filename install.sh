#!/bin/bash

# install.sh - Install git sub-project commands as native Git commands
#
# Usage:
#   sudo ./install.sh              # Install to /usr/local/bin (requires sudo)
#   ./install.sh ~/.local/bin      # Install to user directory (no sudo needed)

set -e  # Exit on error

SCRIPTS=("git-clone-sub-project" "git-create-sub-project")
DEFAULT_INSTALL_DIR="/usr/local/bin"
INSTALL_DIR="${1:-$DEFAULT_INSTALL_DIR}"

echo "Installing git sub-project commands..."
echo ""

# Check if script files exist
for SCRIPT in "${SCRIPTS[@]}"; do
    if [ ! -f "$SCRIPT" ]; then
        echo "Error: $SCRIPT not found in current directory"
        echo "Please run this script from the git-sub-project directory"
        exit 1
    fi
done

# Check if install directory exists
if [ ! -d "$INSTALL_DIR" ]; then
    echo "Error: Installation directory $INSTALL_DIR does not exist"
    exit 1
fi

# Check if we have write permission
if [ ! -w "$INSTALL_DIR" ]; then
    echo "Error: No write permission for $INSTALL_DIR"
    if [ "$INSTALL_DIR" = "$DEFAULT_INSTALL_DIR" ]; then
        echo "Try running with sudo: sudo ./install.sh"
        echo "Or install to user directory: ./install.sh ~/.local/bin"
    fi
    exit 1
fi

# Copy and make executable
for SCRIPT in "${SCRIPTS[@]}"; do
    echo "→ Installing $SCRIPT..."
    cp "$SCRIPT" "$INSTALL_DIR/$SCRIPT"
    chmod +x "$INSTALL_DIR/$SCRIPT"
done

echo ""
echo "✓ Successfully installed to $INSTALL_DIR:"
for SCRIPT in "${SCRIPTS[@]}"; do
    echo "  - $SCRIPT"
done

echo ""
echo "You can now use them as native Git commands:"
echo "  git clone-sub-project <repo_url> <subdir> [branch]"
echo "  git create-sub-project <directory> [remote_url]"
echo ""
echo "Examples:"
echo "  git clone-sub-project git@github.com:user/shared-lib.git my-library"
echo "  git create-sub-project my-library git@github.com:user/shared-lib.git"
echo ""

# Check if they're in PATH
VERIFIED=true
for SCRIPT in "${SCRIPTS[@]}"; do
    if ! command -v "$SCRIPT" &> /dev/null; then
        VERIFIED=false
        break
    fi
done

if [ "$VERIFIED" = true ]; then
    echo "✓ Verified: Commands are in your PATH"
else
    echo "⚠ Warning: $INSTALL_DIR may not be in your PATH"
    if [ "$INSTALL_DIR" = "$HOME/.local/bin" ]; then
        echo ""
        echo "Add this to your ~/.bashrc or ~/.zshrc:"
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
fi

echo ""
echo "Installation complete!"
