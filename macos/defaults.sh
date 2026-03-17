#!/usr/bin/env bash
# macOS defaults — run via install.sh or standalone: bash macos/defaults.sh
set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/config.sh"

# Close System Preferences / System Settings to prevent overriding settings
osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true

# Ask for the administrator password upfront
sudo -v

# Keep sudo alive for the duration of this script
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

###############################################################################
# System                                                                      #
###############################################################################

sudo scutil --set ComputerName  "$COMPUTER_NAME"
sudo scutil --set HostName      "$COMPUTER_NAME"
sudo scutil --set LocalHostName "$COMPUTER_NAME"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$COMPUTER_NAME"

###############################################################################
# Finder                                                                      #
###############################################################################

# Show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# New Finder windows open home directory
defaults write com.apple.finder NewWindowTarget     -string "PfLo"
defaults write com.apple.finder NewWindowTargetPath -string "file://$HOME/"

# Show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Avoid creating .DS_Store on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores     -bool true

# Show ~/Library and /Volumes
chflags nohidden ~/Library && xattr -d com.apple.FinderInfo ~/Library 2>/dev/null || true
sudo chflags nohidden /Volumes

###############################################################################
# Dock                                                                        #
###############################################################################

# Auto-hide Dock
defaults write com.apple.dock autohide -bool true

# Show suggested and recent apps in Dock
defaults write com.apple.dock show-recents -bool true

# Group windows by application in Mission Control
defaults write com.apple.dock expose-group-apps -bool true

###############################################################################
# Trackpad                                                                    #
###############################################################################

# Tap to click
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Drag with drag lock
defaults write com.apple.AppleMultitouchTrackpad Dragging  -bool true
defaults write com.apple.AppleMultitouchTrackpad DragLock  -bool true

###############################################################################
# Lock Screen                                                                 #
###############################################################################

# Lock screen after 20 minutes of inactivity
defaults -currentHost write com.apple.screensaver idleTime -int 1200

###############################################################################
# Control Center                                                              #
###############################################################################

# Show battery percentage in menu bar
defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true

###############################################################################
# Restart affected apps                                                       #
###############################################################################

for app in "Dock" "Finder" "Google Chrome" "Terminal"; do
    killall "$app" &>/dev/null || true
done

echo "Done. Some changes require a logout/restart to take effect."
