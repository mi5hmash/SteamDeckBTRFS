#!/bin/bash

### GLOBAL VARIABLES

## MAIN VARIABLES
ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd); readonly ROOT_DIR
ENV_DESKTOP_DIR=$(xdg-user-dir DESKTOP); readonly ENV_DESKTOP_DIR

## FILENAMES & EXTENSIONS
declare -r e_desktop=".desktop"

## CONFIGURATION - change as per your needs
declare -r ScriptName="SteamDeckBTRFS.sh"
declare -r ToolName="SteamDeckBTRFS"
declare -r GenericName="SteamDeck Script Patcher"
declare -r Version="2.0.6"
declare -r ScriptPath="$ROOT_DIR/$ScriptName"
declare -r IconPath="$ROOT_DIR/icon.ico"
declare -r Comment="PATCH, BACKUP or RESTORE SteamDeck's sdcard related scripts and make your unit friendly with the btrfs formatted sdcards"
declare -r Encoding="UTF-8"
declare -r Terminal="true"
declare -r Type="Application"
declare -r Categories="Application;Utilities"


### MAIN (ENTRY POINT)

declare -r DesktopEntryPath="$ENV_DESKTOP_DIR/$ToolName$e_desktop"

# create desktop entry
cat << EOD > "$DesktopEntryPath"
[Desktop Entry]
Version=$Version
Exec=$ScriptPath
Path=$ROOT_DIR
Icon=$IconPath
Name=$ToolName
GenericName=$GenericName
Comment=$Comment
Encoding=$Encoding
Terminal=$Terminal
Type=$Type
Categories=$Categories
EOD

# mark as trusted on Ubuntu
#gio set "$DesktopEntryPath" metadata::trusted true

# set executable permission to the desktop entry and the script it leds to
chmod u+x "$DesktopEntryPath"
chmod u+x "$ScriptPath"

# exit script
echo "All done. You can safely close this window now."
exit