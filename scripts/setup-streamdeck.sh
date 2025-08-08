#!/usr/bin/env bash

# Stream Deck Setup Script for NixOS
# This script will rebuild your NixOS configuration and set up Stream Deck with microphone control

set -e

echo "🎛️  Stream Deck Setup for NixOS"
echo "=================================="
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "❌ This script should NOT be run as root"
   echo "Please run as your regular user"
   exit 1
fi

echo "📦 Rebuilding NixOS configuration..."
sudo nixos-rebuild switch --flake .

echo ""
echo "🏠 Rebuilding Home Manager configuration..."
home-manager switch --flake .

echo ""
echo "🔌 Checking Stream Deck device connection..."

# Check if Stream Deck is connected
if lsusb | grep -q "0fd9:"; then
    echo "✅ Stream Deck device detected!"
    lsusb | grep "0fd9:"
else
    echo "⚠️  No Stream Deck device detected. Please connect your Stream Deck."
fi

echo ""
echo "🎯 Testing microphone toggle functionality..."

# Test if pamixer works
if command -v pamixer >/dev/null 2>&1; then
    echo "✅ pamixer is available"
    
    # Check if we have audio sources
    if pamixer --list-sources | grep -q "input"; then
        echo "✅ Audio input sources detected"
        
        # Test the mic-toggle script
        if ~/.local/bin/mic-toggle >/dev/null 2>&1; then
            echo "✅ Microphone toggle script is working"
        else
            echo "❌ Microphone toggle script failed. Check audio setup."
        fi
    else
        echo "⚠️  No audio input sources found. Check microphone connection."
    fi
else
    echo "❌ pamixer not found. Something went wrong with the installation."
fi

echo ""
echo "🚀 Starting Stream Deck UI..."

# Check if streamdeck-ui is available
if command -v streamdeck >/dev/null 2>&1; then
    echo "✅ Stream Deck UI is available"
    echo "Starting Stream Deck configuration interface..."
    streamdeck &
    sleep 2
else
    echo "❌ streamdeck command not found. Installation may have failed."
fi

echo ""
echo "📋 Setup Summary"
echo "================"
echo ""
echo "✅ Configuration files updated:"
echo "   - /etc/nixos/hosts/common/streamdeck.nix (system-level config)"
echo "   - /etc/nixos/home/gui/streamdeck.nix (user-level config)"
echo "   - Updated yoga.nix and common.nix to include Stream Deck support"
echo ""
echo "⌨️  Keyboard shortcuts added:"
echo "   - Super + Shift + M: Toggle microphone mute/unmute"
echo "   - XF86AudioMicMute: Standard mic mute key (if available)"
echo ""
echo "🎛️  Stream Deck Configuration:"
echo "   1. Open the Stream Deck UI application"
echo "   2. Configure the TOP-LEFT button (position 0) with:"
echo "      - Command: ~/.local/bin/mic-toggle"
echo "      - Text: MIC"
echo "      - Icon: Choose microphone icon"
echo ""
echo "🔧 Troubleshooting:"
echo "   - If Stream Deck not detected: Check USB connection and try different port"
echo "   - If permissions error: Log out and log back in to reload udev rules"
echo "   - Test mic toggle manually: ~/.local/bin/mic-toggle"
echo "   - Check mic status: ~/.local/bin/mic-status"
echo ""
echo "🎉 Stream Deck setup complete!"
echo ""
echo "Next steps:"
echo "1. Configure your Stream Deck buttons using the Stream Deck UI"
echo "2. Set the top-left button to run: ~/.local/bin/mic-toggle"
echo "3. Test the microphone toggle functionality"
echo ""
