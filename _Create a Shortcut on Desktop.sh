#!/bin/bash

### GET OPTS

# Default values
REMOVE_OPT=false
VERBOSE_OPT=false

# Get opts
while getopts "rv" opt; do
    case $opt in
        r) REMOVE_OPT=true;;
        v) VERBOSE_OPT=true;;
        \?) ;;
    esac
done

# Shift to process remaining arguments
shift $((OPTIND-1))


### GLOBAL VARIABLES

## MAIN VARIABLES
ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd); readonly ROOT_DIR
ENV_DESKTOP_DIR=$(xdg-user-dir DESKTOP); readonly ENV_DESKTOP_DIR

## FILENAMES & EXTENSIONS
declare -r e_desktop=".desktop"

## CONFIGURATION - change as per your needs
declare -r ToolName="SteamDeckBTRFS"
declare -r ScriptName="$ToolName.sh"
declare -r GenericName="SteamDeck Script Patcher"
declare -r Version="2.0.6"
declare -r ScriptPath="$ROOT_DIR/$ScriptName"
declare -r IconPath="$ROOT_DIR/icon.ico"
declare -r Comment="PATCH, BACKUP or RESTORE SteamDeck's sdcard related scripts and make your unit friendly with the btrfs formatted sdcards"
declare -r Encoding="UTF-8"
declare -r Terminal="true"
declare -r Type="Application"
declare -r Categories="Application;Utilities"

declare -r DesktopEntryPath="$ENV_DESKTOP_DIR/$ToolName$e_desktop"

## A function to get a value from a file which is formatted like "NAME=VALUE"
# $1-Setting's Name; $2-File Path
_getSettingsValue() {
local _v=$1
local _f; _f=${2:-"/etc/os-release"}
local _s; _s=$(grep -oP "(?<=^$_v=).+" -m "1" "$_f" | tr -d '"')
echo "${_s:-$unknown}"
}

## OS INFO
s_NAME=$(_getSettingsValue "NAME"); readonly s_NAME
#s_VERSION=$(_getSettingsValue "VERSION_ID"); readonly s_VERSION


### FUNCTIONS

## Creates a Desktop Entry
_createDesktopEntry(){
# Create the Desktop Entry
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

# Mark the Desktop Entry as trusted on Ubuntu
[ "$s_NAME" = "Ubuntu" ] && gio set "$DesktopEntryPath" metadata::trusted true

# Set executable permission to the Desktop Entry and the script it leds to
chmod u+x "$DesktopEntryPath"
chmod u+x "$ScriptPath"

echo "Desktop Entry has been created."
}

## Removes a Desktop Entry
_removeDesktopEntry(){
# Remove the Desktop Entry
rm -f "$DesktopEntryPath"
echo "Desktop Entry has been removed."
}


### MAIN (ENTRY POINT)

case $REMOVE_OPT in
    true) _removeDesktopEntry;;
    *) _createDesktopEntry;;
esac

# Exit script
[ "$VERBOSE_OPT" = false ] && echo "All done. You can safely close this window now."
exit