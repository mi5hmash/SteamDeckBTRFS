#!/bin/bash

### GET OPTS

# Default values
UNINSTALL_OPT=false

# Get opts
while getopts "u" opt; do
    case $opt in
        u) UNINSTALL_OPT=true;;
        \?) ;;
    esac
done

# Shift to process remaining arguments
shift $((OPTIND-1))


### GLOBAL VARIABLES

## MAIN VARIABLES
ENV_DOCUMENTS_DIR=$(xdg-user-dir DOCUMENTS); readonly ENV_DOCUMENTS_DIR

## CONFIGURATION - change as per your needs
declare -r UserName="$USER"
declare -r AuthorName="mi5hmash"
declare -r ToolName="SteamDeckBTRFS"
#declare -r RepoUrl="https://raw.githubusercontent.com/$AuthorName/$ToolName/main"
declare -r TempDir="/tmp/$AuthorName.$ToolName.install"
declare -r InstallDir="$ENV_DOCUMENTS_DIR/$ToolName"
declare -r CreateShortcutScriptDir="$InstallDir/_Create a Shortcut on Desktop.sh"


### STYLES
clr0="\e[0m";
echo_E() { echo -e "\e[1;31m[ERROR] $1$clr0"; }
echo_S() { echo -e "\e[1;96m[SUCCESS] $1$clr0"; }
echo_W() { echo -e "\e[1;93m[WARNING] $1$clr0"; }
echo_I() { echo -e "\e[1;34m[INFO] $1$clr0"; }


### FUNCTIONS

## Asks question using zenity 
# $1-Question
_zenityQuestion() {
zenity --question \
--title="$ToolName Installer" \
--width="300" \
--text="$1" 2> /dev/null

case $? in
	0) echo 1;;
	*) exit;;
esac
}

## Gets info about releases from GitHub's REST API
# $1-API path after 'https://api.github.com/'
# USAGE: _GIT_getInfo "repos/author/tool/releases/latest"
_GIT_getInfo() { curl -sL "https://api.github.com/$1"; }

## Gets version value from json formatted input
# $1-Json formatted input
# USAGE: _GIT_getLatestVersion "$(cat "./test.json")"
_GIT_getLatestVersion() { echo "$1" | jq -r ".tag_name"; }

## Gets download link from json formatted input
# $1-Json formatted input; $2-Filename
# USAGE: _GIT_getDownloadLink "$(cat "./test.json")"
_GIT_getDownloadLink() { echo "$1" | jq -r ".assets[] | select(.name | contains(\"$2\")) | .browser_download_url"; }

## Looks for the latest release tag on GitHub and creates a download link
_GIT_GetURL() {
local _i; _i="$(_GIT_getInfo "repos/$AuthorName/$ToolName/releases/latest")"
local _v; _v="$(_GIT_getLatestVersion "$_i")"
local _f; _f=$ToolName\_$_v.zip
_GIT_getDownloadLink "$_i" "$_f"
}

## Greetings
_sayHello() {
local _i; _i="$(date +%H)" # Get the current hour
local _a=", $UserName! \(^-^)/"
if [ "$_i" -ge 5 ] && [ "$_i" -lt 12 ]; then
	echo "Good morning$_a"
elif [ "$_i" -ge 12 ] && [ "$_i" -lt 18 ]; then
	echo "Good afternoon$_a"
else
	echo "Good evening$_a"
fi
}
_sayGoodbye() {
local _i; _i="$(date +%H)" # Get the current hour
local _a=", $UserName! (^-^)"
if [ "$_i" -ge 5 ] && [ "$_i" -lt 12 ]; then
	echo "Have a great day$_a"
elif [ "$_i" -ge 12 ] && [ "$_i" -lt 18 ]; then
	echo "Enjoy your afternoon$_a"
else
	echo "Good night$_a"
fi
}

## Exit Logic
_exit() {
PS3="#?" # Restore the default Select Prompt (PS3)
echo -e "\nExiting...\n$(_sayGoodbye)"
echo "You can safely close this window now."; exit
}

## Downloads latest release from GitHub and installs it.
# $1-Download Link; $2-Instal Directory
_downloadAndUnpack() {
_eFail() { echo -e "\e[1;31mFailure\e[0m"; }
_eSucc() { echo -e "\e[1;96mSuccess\e[0m"; }
local _dl; _dl=$1
local _id; _id=$2
local _ret;
local _fileName; _fileName="update_$(uuidgen | tr "[:lower:]" "[:upper:]").zip"
echo_I "Trying to download the latest version..."
wget -q --show-progress -O "$TempDir/$_fileName" -- "$_dl" &> /dev/null # download the file
_ret="$?"; [ "$_ret" = 0 ] && _eSucc || _eFail
echo_I "Trying to install..."
mkdir -p -- "$_id"
unzip -oq "$TempDir/$_fileName" -d "$_id" # unpack the file
_ret="$?"; [ "$_ret" = 0 ] && _eSucc || _eFail
}

## Install Logic
function installMe() {
_zenityQuestion "Do you want to INSTALL the $ToolName by $AuthorName?" &> /dev/null
echo_I "Creating a temporary folder '$TempDir'..."
mkdir -p -- "$TempDir"
_downloadAndUnpack "$(_GIT_GetURL)" "$InstallDir"
echo_I "Granting execute permission..."
chmod u+x "$CreateShortcutScriptDir"
echo_I "Creating shortcut on Desktop..."
"$CreateShortcutScriptDir" -v
echo_I "Removing the temporary folder '$TempDir'..."
rm -rf -- "$TempDir"
echo_S "The program has been installed."
}

## Uninstall Logic
function uninstallMe() {
_zenityQuestion "Do you want to UNINSTALL the $ToolName by $AuthorName?" &> /dev/null
echo_I "Removing shortcut from Desktop..."
chmod u+x "$CreateShortcutScriptDir"
"$CreateShortcutScriptDir" -rv
echo_I "Uninstalling..."
rm -rf -- "$InstallDir"
echo_S "The program has been uninstalled."
}


### MAIN (ENTRY POINT)

_sayHello
echo ""

echo "$ToolName Installer by $AuthorName"
echo "License: MIT: https://github.com/$AuthorName/$ToolName/blob/main/LICENSE"
echo "Source: https://github.com/$AuthorName/$ToolName"
echo ""

case $UNINSTALL_OPT in
    true) uninstallMe;;
    *) installMe;;
esac

_exit