#!/bin/bash
# Installation script for the docker_nvim_quickstart Oh My Zsh plugin
#
# Default: symlinks this directory into $ZSH_CUSTOM/plugins/, so edits made
# here (Dockerfile.nvim, start_docker_nvim.sh, ...) take effect immediately
# with no re-install step. Pass --copy for a standalone, decoupled copy
# instead (e.g. if you're distributing this plugin apart from this repo).

set -e

MODE="symlink"
if [ "${1:-}" = "--copy" ]; then
    MODE="copy"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== docker_nvim_quickstart Plugin Installer ===${NC}\n"

# Check prerequisites
echo "Checking prerequisites..."

# Check for Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${RED}✗ Oh My Zsh not found${NC}"
    echo "Please install Oh My Zsh first: https://ohmyz.sh/#install"
    exit 1
fi
echo -e "${GREEN}✓ Oh My Zsh found${NC}"

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker not found${NC}"
    echo "Please install Docker first: https://docs.docker.com/engine/install/"
    exit 1
fi
echo -e "${GREEN}✓ Docker found${NC}"

if docker buildx version &> /dev/null; then
    echo -e "${GREEN}✓ docker buildx found (used when available; falls back to classic docker build)${NC}\n"
else
    echo -e "${YELLOW}⚠ docker buildx not found — will fall back to classic 'docker build'${NC}\n"
fi

# Installation
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/docker_nvim_quickstart"

# Check if already installed (a symlink counts as -d too, via -e below)
if [ -e "$PLUGIN_DIR" ]; then
    echo -e "${YELLOW}Plugin directory already exists at:${NC}"
    echo "$PLUGIN_DIR"
    read -p "Overwrite? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 0
    fi
    rm -rf "$PLUGIN_DIR"
fi

echo "Installing plugin ($MODE)..."
if [ "$MODE" = "symlink" ]; then
    ln -s "$SCRIPT_DIR" "$PLUGIN_DIR"
else
    mkdir -p "$PLUGIN_DIR"
    cp "$SCRIPT_DIR/docker_nvim_quickstart.plugin.zsh" "$PLUGIN_DIR/"
    cp "$SCRIPT_DIR/_docker_nvim_quickstart" "$PLUGIN_DIR/"
    cp "$SCRIPT_DIR/start_docker_nvim.sh" "$PLUGIN_DIR/"
    cp "$SCRIPT_DIR/Dockerfile.nvim" "$PLUGIN_DIR/"
    cp "$SCRIPT_DIR/entrypoint_omz.sh" "$PLUGIN_DIR/"
    cp "$SCRIPT_DIR/README.md" "$PLUGIN_DIR/"
    chmod +x "$PLUGIN_DIR/start_docker_nvim.sh" "$PLUGIN_DIR/entrypoint_omz.sh"
fi

echo -e "${GREEN}✓ Plugin installed to: $PLUGIN_DIR${NC}\n"

# Update .zshrc
echo "Checking .zshrc configuration..."
if grep -q "docker_nvim_quickstart" "$HOME/.zshrc"; then
    echo -e "${GREEN}✓ Plugin already in .zshrc${NC}"
else
    echo "Adding plugin to .zshrc..."
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup"
    sed -i.bak 's/plugins=(\(.*\))/plugins=(\1 docker_nvim_quickstart)/' "$HOME/.zshrc"
    rm -f "$HOME/.zshrc.bak"
    echo -e "${GREEN}✓ Added to .zshrc (backup saved to .zshrc.backup)${NC}"
fi

echo ""
echo -e "${GREEN}=== Installation Complete ===${NC}"
echo ""
echo "Next steps:"
echo "1. Reload your shell: source ~/.zshrc"
echo "2. Test the plugin: dnvim --help"
echo ""
echo "Quick start (run from the project directory you want to develop in):"
echo "  dnvim python:3.11         # build (first time) and attach"
echo "  dnvim node:20"
echo "  dnvim ls                  # list locally-built *.nvim images"
echo "  dnvim rebuild python:3.11 # force a rebuild"
echo "  dnvim rm <container-name> # remove a dev container"
echo ""
echo "For more info: cat $PLUGIN_DIR/README.md"
