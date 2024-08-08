#!/bin/bash

### STYLES
clr0="\e[0m"; clr1="\e[1;94m"; clr2="\e[1;95m"
echo_E() { echo -e "\e[1;31m[ERROR] $1$clr0"; }
echo_S() { echo -e "\e[1;96m[SUCCESS] $1$clr0"; }
echo_W() { echo -e "\e[1;93m[WARNING] $1$clr0"; }
echo_I() { echo -e "\e[1;34m[INFO] $1$clr0"; }


### FUNCTIONS

## Tells if the device is connected to the Internet
_testConnection() {
local _t; _t="$(ping -q -c2 "8.8.8.8" | grep -E -o -m 1 '([[:digit:]]{1,3}'%')')"
[ "$_t" != "100%" ]
}

## Random password generator
# $1-Password length
_randomPasswordGen() { tr -dc 'A-Za-z0-9!"#%&$'\''()*+,-./:;<>=?@[]\^_`|{}~' </dev/urandom | head -c "${1:-16}"; echo; }

## Waits n seconds before proceeding any further
# $1-Number of seconds to wait
# USAGE: _simpleTimer "5"
_simpleTimer() {
local _t="$1"
echo -n "Script will continue in: $_t"
for (( i="$_t-1"; i>=0; i-- ))
do
	sleep 1s
	echo -n ", $i"
done
echo "."
}

## Return first n characters
# $1-Input string; $2-Length
# USAGE: "$(left "test" 2)"
left() { echo "${1::$2}"; }
## Return string without first n characters
leftc() { echo "${1::$2}"; }

## Return last n characters
# $1-Input string; $2-Length
# USAGE: "$(right "test" 2)"
right() { echo "${1:${#1}-$2:$2}"; }
## Return string without last n characters
rightc() { echo "${1:0:$2}"; }

## Return string of a specified length starting from the given offset
# $1-Input string; $2-Offset; $3-Length
# USAGE: "$(substr "test" 1 1)"
substr() { echo "${1:$2:$3}"; }
## Cut characters from the left and right side of an input string
# $1-Input string; $2-Chars to cut from left; $3-Chars to cut from right
substrc() { echo "${1:$2:$((-$3))}"; }

## Remove color codes from a string
# $1-Input string
uncolorizeStr() { echo "$1" | sed -r 's/\\e\[[[:digit:]]+;[[:digit:]]+m//g'; }

## Repeat input string n times
# $1-Input string; $2-Times
# USAGE: "$(say "a" 10)"
say() { for _ in $(seq 1 "${2:-1}"); do echo -n "$1"; done; }

## Write a pattern of the specified length
# $1-Pattern; $2-Length
# USAGE: "$(sayp "a" 10)"
sayp() {
local _u; _u="$(uncolorizeStr "$1")"
local _a; _a="$(($2 / ${#_u}))"
echo -n "$(say "$1" $_a)"
_a="$(($2 % ${#_u}))"
echo -n "$(left "$1" $_a)"
}

## Write the input string in the middle of the line
# $1-Input string; $2-Line width; $3-Pattern
# USAGE: "$(saym "a" 10)"
saym() {
local _u; _u="$(uncolorizeStr "$1")"
local _p; _p="$(( ( $2 - ${#_u} ) / 2 ))"
echo -n "$(sayp "${3:- }" $_p)"
echo -n "$1"
_p="$(( _p + (( $2 - ${#_u} ) % 2) ))"
echo -n "$(sayp "${3:- }" $_p)"
}

## Write the input string alligned to the right
# $1-Input string; $2-Line width; $3-Pattern
# USAGE: "$(sayr "a" 10)"
sayr() {
local _u; _u="$(uncolorizeStr "$1")"
local _p; _p="$(( $2 - ${#_u} ))"
echo -n "$(sayp "${3:- }" $_p)"
echo "$1"
}

## Get password variable
_getPassword() { _decrypt "$passWord"; }
## Set password variable
_setPassword() { passWord=$(_encrypt "$1"); }

_readUserSec() { _decrypt "$(cat $UserSecPath)" "$SEC_KEY"; }
_writeUserSec() { _encrypt "$1" "$SEC_KEY" > $UserSecPath; }

## A function to get a value from a file which is formatted like "NAME=VALUE"
# $1-Setting's Name; $2-File Path
_getSettingsValue() {
local _v=$1
local _f; _f=${2:-"/etc/os-release"}
local _s; _s=$(grep -oP "(?<=^$_v=).+" -m "1" "$_f" | tr -d '"')
echo "${_s:-$unknown}"
}

## Creates a timestamp like '-YYYYMMSShhmmssnn'
# $1-Input Path
_createTimestamp() { echo "$1-$(date +%Y%m%d%H%M%S%N | cut -c 1-16)"; }

## Checks if user exists
# $1-Username
_userExists() { [ "$(id -u "$1" 2> /dev/null)" ]; }

## Checks if user has its password set
# $1-Username
_userHasPassword() { [ "$(passwd -S "$1" | cut -d " " -f 2)" = "P" ]; }

## Returns current user sudo status
_sudoStatus() {
local _t; _t=$(sudo -nv 2>&1)
if [ -z "$_t" ]; then
	echo 2 # has_sudo__pass_set
elif echo "$_t" | grep -q '^sudo:'; then
	echo 1 # has_sudo__needs_pass
else
	echo 0 # no_sudo
fi
}
_sudoStatusText() {
local _t; _t="$(_sudoStatus)"
case "$_t" in
	0) echo "\e[1;31m""unavailable$clr0";;
	1) echo "\e[1;93m""non-active$clr0";;
	2) echo "\e[1;96m""active$clr0";;
esac
}

## Set password for user account
# $1-Username; $2-Password
_setUserPassword() {
passwd "$1" << EOD &> /dev/null
$2
$2
EOD
}

## Try to set password for user account
# $1-Username; $2-Password
setUserPassword() {
local _userName; _userName=${1:-$userName}
local _passWord; _passWord=${2:-$(_getPassword)}
# Check if user exists
if ! _userExists "$_userName"; then
	echo_E "User '$_userName' does not exist!"
	return
fi
# Check if user already has its password set
if _userHasPassword "$_userName"; then
	echo_I "User '$_userName' already has its password set."
else
	# Try to set user password
	_setUserPassword "$_userName" "$_passWord"
	# Check if password has been set
	if _userHasPassword "$_userName"; then
		echo_S "Password for the '$_userName' account has been set."
	else
		echo_E "Password couldn't be set!"
		return
	fi
fi
}

## Remove password from user account
# $1-Username
_removeUserPassword() { sudo -S passwd -d "$1" &> /dev/null; }

## Remove password from the user account
# $1-Username
removeUserPassword() {
local _userName; _userName=${1:-$userName}
# Check if user exists
if ! _userExists "$_userName"; then
	echo_E "User '$_userName' does not exist!"
	return
fi
# Check if user already has its password set
if ! _userHasPassword "$_userName"; then
	echo_I "User '$_userName' does not have a password set."
else
	# Try to remove user password
	_removeUserPassword "$_userName"
	# Check if password has been removed
	if ! _userHasPassword "$_userName"; then
		echo_S "Password from the '$_userName' account has been removed."
		sudo -k # Invalidate user's cached credentials
	else
		echo_E "Password couldn't be removed!"
		return
	fi
fi
}

## AES-256 (DE/EN)CRYPTION
# $1-Input string
# Reference: https://www.howtogeek.com/734838/how-to-use-encrypted-passwords-in-bash-scripts/
_encrypt() {
local _p; _p=${2:-$SESSION_GUID} # set default password
echo "$1" | openssl enc -aes-256-cbc -md sha512 -a -pbkdf2 -iter 100000 -salt -pass "pass:$_p"
}
_decrypt() {
local _p; _p=${2:-$SESSION_GUID} # set default password
echo "$1" | openssl enc -aes-256-cbc -md sha512 -a -d -pbkdf2 -iter 100000 -salt -pass "pass:$_p"
}

## Read password from user input if it does have one set
_readExistingUserPassword() {
local _p; _p=$(_getPassword)
local _f=0 # helps to omit the encryption on the first try (when the script tries out a default password)
while true; do
	# if given password is valid then encrypt it
	echo_I "Trying out the given password..."
	if [ "$(_validateSudoPassword "$_p")" = 1 ]; then
		[ $_f = 1 ] && _setPassword "$_p" && 
		[ "$REMEMBER_PASSWORD" = "1" ] && _writeUserSec "$_p"
		break
	fi
	_f=1
	echo_W "Invalid password. Please, enter a correct sudo password."
	echo_I "Typed characters will not appear."
	# Get input from user
	read -rsp "Sudo password:"; _p="$REPLY"; echo
done
}

## Validate Sudo Password and claim root rights
_validateSudoPassword() {
local _t; _t=$(echo "$1" | sudo -Svp '' 2>&1) # test
local _vo; _vo=${2:-0} # validate_only flag
if [ -z "$_t" ]; then
	echo 1 # sudo_pswd_valid
	[ "$_vo" = 1 ] && sudo -k # Invalidate user's cached credentials
fi
}

## Check user's sudo rights and elevate it if possible
checkSudo() {
echo
# Check if user is a sudoer
local _t; _t="$(_sudoStatus)"
if [ "$_t" = 1 ]; then
	# Check if user has its password set
	if _userHasPassword "$userName"; then
		_readExistingUserPassword
	else
		setUserPassword "$userName"
	fi
	_validateSudoPassword "$(_getPassword)" &> /dev/null
else
	sudo -v # Extend current sudo session
fi
_steamOsReadOnlyDisable # Disable Readonly protection
}

## Restores SteamOsReadOnly status if needed and removes user password if user didn't have one set on script launch
sudoTaskFinalize() {
[ "$DEF_RO_STATUS" = "enabled" ] && _steamOsReadOnlyEnable
[ "$DEF_USR_HAS_PASSWD" = 0 ] && removeUserPassword "$userName"
}

## Change the SteamOS filesystem to read-write
_steamOsReadOnlyDisable() {
local _t; _t="$(sudo steamos-readonly status)" # test
if [ "$_t" = "disabled" ]; then
	echo_I "SteamOS filesystem is already set to read-write."
else
	sudo steamos-readonly disable
	echo_S "Changed the SteamOS filesystem to read-write."
fi
}

## Change the SteamOS filesystem to readonly
_steamOsReadOnlyEnable() {
local _t; _t="$(sudo steamos-readonly status)" # test
if [ "$_t" = "enabled" ]; then
	echo_I "SteamOS filesystem is already readonly."
else
	sudo steamos-readonly enable
	echo_S "Changed the SteamOS filesystem to readonly."
fi
}

## Toggles DEF_RO_STATUS
# Previously it used a hidden function which toggles readonly status "$(sudo steamos-readonly toggle)", but it didn't work out for the logic I wrote.
steamOsReadOnlyToggle() {
local _c # color
if [ "$DEF_RO_STATUS" = "enabled" ]; then DEF_RO_STATUS="disabled"; _c="\e[1;31m"; 
else DEF_RO_STATUS="enabled"; _c="\e[1;96m"; fi
echo -e "SteamOS filesystem readonly is now $_c$DEF_RO_STATUS$clr0."
}

## Read steamos-readonly status without sudo need
_steamOsReadOnlyStatusBTRFS() {
local _e="enabled" _d="disabled"
if [ "$s_ROOTFS_TYPE" = "btrfs" ]; then
	if [ -n "$1" ]; then
		[ "$(btrfs property get / ro)" = "ro=true" ] && echo "\e[1;96m$_e$clr0" || echo "\e[1;31m$_d$clr0"
	else
		[ "$(btrfs property get / ro)" = "ro=true" ] && echo "$_e" || echo "$_d"
	fi
else
	[ -n "$1" ] &&	echo "\e[1m""$unknown" || echo "$unknown"
fi
}

## Initialize pacman's keyring
_pacmanKeyringInit() {
	sudo pacman-key --init && sudo pacman-key --populate && sudo pacman -Syu --noconfirm
}

## Install package using pacman
# $1-Package Name
_installPackageWithPacman() {
	local _p="$1"
	# check if a specific package is installed
	pacman -Qi "$_p" &> /dev/null
	local _er="$?"
	[ "$_er" = 0 ] && return
	[ "$PACMAN_REFRESHED" = 0 ] && echo_I "Trying to initialize pacman's keyring..." && _pacmanKeyringInit
	PACMAN_REFRESHED=1
	echo_I "Trying to install '$_p' package..." && sudo pacman -S "$_p" --noconfirm &> /dev/null
	# re-check if a specific package is installed
	pacman -Qi "$_p" &> /dev/null
	_er="$?"
	[ "$_er" = 0 ] && echo_S "The '$_p' package got installed." && return
	echo_E "Couldn't install '$_p' package."
}


### BACKUP

## Backup scripts from SteamDeck
backupScripts() {
local _timestamp; _timestamp="$(_createTimestamp "")"
local _backup="$s_BUILD$_timestamp$e_backup"
local _tempDir="$TempPath$s_BUILD$_timestamp/"
echo_I "Trying to backup the scripts..."
mkdir -p -- "$BackupPath" "$_tempDir"
(for f in "${ScriptFiles[@]}"
do
	_backupScript "$f" "$_tempDir" || exit 3
done
echo_I "Examining files..."
# Create file with sha256 checksums
_dirSHA256sumRW "$_tempDir" "$_tempDir$n_checksums_o" || exit 4
# Create 'chmod' file
_backupChmod "$SteamDeckFilesPath" "$_tempDir$n_chmod" || exit 5
# Create 'build' file
echo "$s_BUILD" > "$_tempDir$n_build" || exit 6
# Create 'version' file
echo "$PACKAGE_VERSION" > "$_tempDir$n_version" || exit 7
echo_I "Trying to pack backup..." # Pack backup
_tarPack "$_tempDir" "$BackupPath$_backup" || exit 8)
local _err="3:$?"
local _errb="{$_err} Creating a backup file has failed"
case "$_err" in
	3:0) echo_S "Backup file '$_backup' has been created in the '$BackupPath' directory.";;
	3:3) echo_E "$_errb on copying files.";;
	3:8) echo_E "$_errb on packing.";;
	*) echo_E "$_errb.";;
esac
# Remove directory
rm -rf -- "$TempPath"
}

## Restore scripts from backup
# $1-Backup File Name
restoreScripts() {
local _backup="$1"
local _tempDir="$TempPath${_backup%.*}/"
mkdir -p -- "$_tempDir"
echo_I "Trying to unpack backup..." # Unpack
(tar -xzf "$BackupPath$_backup" -C "$_tempDir" || exit 8
echo_I "Testing compatibility..."
# Test version
[ "$(cat "$_tempDir$n_version")" -le "$PACKAGE_VERSION" ] || exit 7
# Test build
[ "$(cat "$_tempDir$n_build")" = "$s_BUILD" ] || exit 6
echo_I "Verifying checksums..." # Verify sha256 checksums
_dirSHA256sumRW "$_tempDir" "$_tempDir$n_checksums_o" 1 || exit 4
echo_I "Trying to restore the scripts..." # Replace scripts
for f in "${ScriptFiles[@]}"
do
	_restoreScript "$f" "$_tempDir" || exit 3
done
echo_I "Restoring files permissions..." # Fix permissions of a replaced script
_restoreChmod "$SteamDeckFilesPath" "$_tempDir$n_chmod" || exit 5)
local _err="4:$?"
local _errb="{$_err} Restoring a backup has failed"
case "$_err" in
	4:0) echo_S "Scripts from a backup file '$_backup' has been restored.";;
	4:3) echo_E "$_errb on copying files.";;
	4:5) echo_E "$_errb on restoring files permissions.";;
	4:4|4:6) echo_E "$_errb on testing.";;
	4:7) echo_E "{$_err} Backup has been made with a newer version of $TOOL_NAME tool. Please download the newest version from: $git_link/releases";;
	4:8) echo_E "$_errb on unpacking.";;
	*) echo_E "$_errb.";;
esac
# Remove directory
rm -rf -- "$TempPath"
}

## Backup a script from SteamDeck
# $1-Filename; $2-Output directory path
_backupScript() {
cp -f "$SteamDeckFilesPath$1" "$2$1" &> /dev/null &&
echo_S "Script '$1' has been backupped." ||
(echo_E "Script '$1' couldn't be backupped."; exit 1)
}

## Restore a script from Backup
# $1-Filename; $2-Output directory path
_restoreScript() {
sudo cp -f "$2$1" "$SteamDeckFilesPath$1" &> /dev/null &&
echo_S "Script '$1' has been restored." ||
(echo_E "Script '$1' couldn't be restored."; exit 1)
}


### PATCHING

patchScripts() {
local _tempDir="$TempPath$s_BUILD/"
local _patch="$s_PATCH_CANDIDATE"
mkdir -p -- "$_tempDir" "$PatchPath"
echo_I "Searching for a patch..."
( [ -n "$_patch" ] && [ -e "$PatchPath$_patch" ] || exit 3
echo_S "Patch file found."
echo_I "Trying to unpack..." # Unpack
tar -xzf "$PatchPath$_patch" -C "$_tempDir" || exit 8
echo_S "Patch upacked."
echo_I "Verifying checksums..." # Verify sha256 checksums
_dirSHA256sumRW "$SteamDeckFilesPath" "$_tempDir$n_checksums_o" 1 || exit 4
echo_S "Files checksums verified."
_installPackageWithPacman "patch" # Try to install patch package if it's not installed
echo_I "Trying to patch..."
sudo patch --dry-run -fruN -d "$SteamDeckFilesPath" < <(zcat "$_tempDir$n_patch$e_patch") || exit 7
sudo patch -fruN -d "$SteamDeckFilesPath" < <(zcat "$_tempDir$n_patch$e_patch"))
local _err="1:$?"
local _errb="{$_err} Patching script files has failed"
case "$_err" in
	1:0) echo_S "Scripts files on your SteamDeck has been patched."; s_PATCH_STATE="P";;
	1:3) echo_E "{$_err} There is no patch file for your current build '$s_BUILD' in the '$PatchPath' directory.";;
	1:4) echo_E "{$_err} Files' checksums don't match.";;
	*) echo_E "$_errb.";;
esac
# Remove directory
rm -rf -- "$TempPath"
}

unpatchScripts() {
local _tempDir="$TempPath$s_BUILD/"
local _patch="$s_PATCH_CANDIDATE"
mkdir -p -- "$_tempDir" "$PatchPath"
echo_I "Searching for a patch..."
( [ -n "$_patch" ] && [ -e "$PatchPath$_patch" ] || exit 3
echo_S "Patch file found."
echo_I "Trying to unpack..." # Unpack
tar -xzf "$PatchPath$_patch" -C "$_tempDir" || exit 8
echo_S "Patch upacked."
echo_I "Verifying checksums..." # Verify sha256 checksums
_dirSHA256sumRW "$SteamDeckFilesPath" "$_tempDir$n_checksums_p" 1 || exit 4
echo_S "Files checksums verified."
_installPackageWithPacman "patch" # Try to install patch package if it's not installed
echo_I "Trying to unpatch..."
sudo patch --dry-run --ignore-whitespace -ruN -d "$SteamDeckFilesPath" < <(zcat "$_tempDir$n_patch$e_unpatch") || exit 7
sudo patch -ruN --ignore-whitespace -d "$SteamDeckFilesPath" < <(zcat "$_tempDir$n_patch$e_unpatch"))
local _err="2:$?"
local _errb="{$_err} Unpatching script files has failed"
case "$_err" in
	2:0) echo_S "Scripts files on your SteamDeck has been unpatched."; s_PATCH_STATE="O";;
	2:3) echo_E "{$_err} There is no patch file for your current build '$s_BUILD' in the '$PatchPath' directory.";;
	2:4) echo_E "{$_err} Files' checksums don't match.";;
	*) echo_E "$_errb.";;
esac
# Remove directory
rm -rf -- "$TempPath"
}


### WORKBENCH

## Prepares Workspace to manually patch the files
# $1-Backup File Name
_prepareWorkbench() {
local _backup="$1"
local _wrkbDir="$WorkbenchPath"
local _orgfPath="$_wrkbDir${OriginalFilesPath#*./}"
local _intelfPath="$_wrkbDir${OriginalFilesIntelPath#*./}"
local _patchedfPath="$_wrkbDir${PatchedFilesPath#*./}"
_prepareWorkbench_cleanup() { rm -rf -- "$_wrkbDir"; }
# Recreate workspace folders
_prepareWorkbench_cleanup
mkdir -p -- "$_intelfPath" "$_orgfPath" "$_patchedfPath"
echo_I "Unpacking the backup archieve..." # unpack
( tar -xzf "$BackupPath$_backup" -C "$_intelfPath" || exit 8
echo_I "Verifying checksums..." # verify sha256 checksums
_dirSHA256sumRW "$_intelfPath" "$_intelfPath$n_checksums_o" 1 || exit 4
# Copy scripts
echo_I "Copying files..."
for f in "${ScriptFiles[@]}"
do
	cp -f "$_intelfPath$f" "$_orgfPath$f" &> /dev/null || exit 3
	cp -f "$_orgfPath$f" "$_patchedfPath$f" &> /dev/null || exit 3
	rm -f "$_intelfPath$f" || exit 3
done )
local _er="$?"
local _err="98:$_er"
local _errb="{$_err} Creating a workspace has failed"
[ "$_er" = 0 ] || _prepareWorkbench_cleanup # cleanup on failure
case "$_err" in
	98:0) echo_S "Scripts from a backup file '$_backup' has been unpacked to '$_orgfPath' and '$_patchedfPath' along with intel in '$_intelfPath'.";;
	98:3) echo_E "$_errb on copying files";;
	98:4) echo_E "$_errb on veryfying";;
	98:8) echo_E "$_errb on unpacking";;
	*) echo_E "$_errb.";;
esac
}

createPatchFile() {
local _tempDir="$TempPath$s_BUILD/"
local _wrkbDir="$WorkbenchPath"
local _orgfPath="$_wrkbDir${OriginalFilesPath#*./}"
local _patchedfPath="$_wrkbDir${PatchedFilesPath#*./}"
local _patchesCsv="$PatchPath$n_patches$e_csv"
local _patchesOwnCsv="$PatchPath$n_patches_own$e_csv"
mkdir -p -- "$_tempDir" "$PatchPath"
# Check if the patch file already exists.
if [ -e "$_orgfPath" ] && [ -e "$_patchedfPath" ]; then
	local _hash1; _hash1="$(_generateIntegrityHash "$_orgfPath")"
	local _hash2; _hash2="$(_generateIntegrityHash "$_patchedfPath")"
	local _guid; _guid="$(uuidgen)"
	local _text; _text="$_hash1;$_guid;O\n$_hash2;$_guid;P"
	local _patch; _patch="$_guid$e_patch"
	local _t
	[ -e "$_patchesOwnCsv" ] && _t=$(grep "$_hash1" "$_patchesOwnCsv")
	[ -z "$_t" ] && [ -e "$_patchesCsv" ] && _t=$(grep "$_hash1" "$_patchesCsv")
fi
( [ -e "$_orgfPath" ] && [ -e "$_patchedfPath" ] || exit 9
[ -n "$_t" ] && exit 10
# Create a real patch and unpatch files, compressed with gzip compression level 9
# More info about creating patches: https://www.howtogeek.com/415442/how-to-apply-a-patch-to-a-file-and-create-patches-in-linux/
echo_I "Comparing files..."
diff -ruN "$_orgfPath" "$_patchedfPath" | gzip -9 > "$_tempDir$n_patch$e_patch"
[ "${PIPESTATUS[0]}" -le 1 ] || exit 3
echo_S "Patch file created."
diff -ruN "$_patchedfPath" "$_orgfPath" | gzip -9 > "$_tempDir$n_patch$e_unpatch"
[ "${PIPESTATUS[0]}" -le 1 ] || exit 3
echo_S "Reverse patch file created."
# Create file with sha256 checksums
_dirSHA256sumRW "$_orgfPath" "$_tempDir$n_checksums_o" || exit 4
_dirSHA256sumRW "$_patchedfPath" "$_tempDir$n_checksums_p" || exit 5
echo_S "Files with checksums created."
# Create 'build' file
echo_I "Collecting info about SteamOS build and tool version..."
echo "$s_BUILD" > "$_tempDir$n_build" || exit 6
# Create 'version' file
echo "$PACKAGE_VERSION" > "$_tempDir$n_version" || exit 7
echo_S "Info about build and version collected."
# Pack all files with a fake *.patch extension
echo_I "Trying to pack..."
_tarPack "$_tempDir" "$PatchPath$_patch" || exit 8)
local _err="99:$?"
local _errb="{$_err} Creating a patch file has failed"
case "$_err" in
	99:0) echo_S "Patch file '$_patch' has been created in the '$PatchPath' directory."; echo -e "$_text" >> "$_patchesOwnCsv";;
	99:7) echo_E "$_errb on packing.";;
	99:9) echo_E "{$_err} Workbench directory does not exist or has a wrong structure.";;
	99:10) echo_E "{$_err} Patch file already exists.";;
	*) echo_E "$_errb.";;
esac
# Remove directory
rm -rf -- "$TempPath"
}

## Generates Inegrity Hash for the files in ScriptFiles collection
# $1-Script Files Root Path
_generateIntegrityHash() {
	local _c;
	local _t;
for f in "${ScriptFiles[@]}"
do
	mapfile -t -d " " _t < <(sha256sum -b -- "$1$f" 2>/dev/null)
	_c=$_c"|"${_t[0]}
done
mapfile -t -d " " _t < <(echo -n "${_c:1}" | md5sum)
echo "${_t[0]}"
}

## Calculate SHA256 checksums of files in directory
# $1-Intput File Path; $2-Output File Path; if $3 not null then read instead of write;
_dirSHA256sumRW() {
local _s=1 #status - preassume function failure
cd -- "$1" || return
if [ -z "$3" ]; then
	sha256sum -b -- * > "$OLDPWD/$2" # write
else	
	sha256sum --status -c -- "$OLDPWD/$2" # read
fi
_s=$? # store status
cd -- "$OLDPWD" || return
[ "$_s" = 0 ]
}

## Backup Chmod
# $1-Root Directory of a File Collection; $2-Output File Path; if $3 not null then delete old file;
_backupChmod() {
# Delete previous file if exist
[ -n "$3" ] && rm -f -- "$2"
for f in "${ScriptFiles[@]}"
do
	echo -e "$f\t$(stat -c %a "$1$f")" >> "$2"
done
}

## Restore Chmod
# $1-Root Directory of a File Collection; $2-Input File Path
_restoreChmod() {
local _x _y
readarray -t _y < "$2"
for y in "${_y[@]}"
do
	readarray -td '	' _x < <(echo -n "$y")
	sudo chmod "${_x[1]}" "$1${_x[0]}"
done
}

## Pack directory (*.tar.gz)
# $1-Root directory of files to pack; $2-Archieve Output Path
_tarPack() {
local _s=0 # status - preassume function will succeed
cd -- "$1" || return
tar -cf -- * | gzip -9 > "$OLDPWD/$2"
_s=${PIPESTATUS[0]}
cd -- "$OLDPWD" || return
[ "$_s" = 0 ]
}


### UPDATES

## Gets info about releases from GitHub's REST API
# $1-API path after 'https://api.github.com/'
# USAGE: _GIT_getInfo "repos/mi5hmash/SteamDeckBTRFS/releases/latest"
_GIT_getInfo() { curl -sL "https://api.github.com/$1"; }

## Gets version value from json formatted input
# $1-Json formatted input
# USAGE: _GIT_getLatestVersion "$(cat "./test.json")"
_GIT_getLatestVersion() { echo "$1" | jq -r ".tag_name"; }

## Gets download link from json formatted input
# $1-Json formatted input; $2-Filename
# USAGE: _GIT_getDownloadLink "$(cat "./test.json")"
_GIT_getDownloadLink() { echo "$1" | jq -r ".assets[] | select(.name | contains(\"$2\")) | .browser_download_url"; }

## Compares the global version with a local version provided by user
# $1-Global version number; $2-Local version number
_isUpdateAvailable() {
local _g=$1
local _l=$2
local _t; _t=$(echo -e "$_g\n$_l" | sort -Vr | head -n 1)
(
	[ "$_l" = "$_g" ] && exit 1 # up-to-date
	[ "$_t" = "$_g" ] && exit 2 # update available
	[ "$_t" = "$_l" ] && exit 3 # version from the future
)
echo "$?"
}

## Downloads latest release from GitHub
# $1-Download link
_GIT_update() {
_eFail() { echo -e "\e[1;31mFailure\e[0m"; }
_eSucc() { echo -e "\e[1;96mSuccess\e[0m"; }
local _ret;
local _dl; _dl=$1
local _fileName; _fileName="update_$(uuidgen | tr "[:lower:]" "[:upper:]")$e_zip"
echo_I "Trying to download the update:"
wget -q --show-progress -O "$_fileName" -- "$_dl" &> /dev/null # download the update file
_ret="$?"; [ "$_ret" = 0 ] && _eSucc || _eFail
echo_I "Trying to update:"
unzip -oq "./$_fileName" # unpack the update file
_ret="$?"; [ "$_ret" = 0 ] && _eSucc || _eFail
rm -f "./$_fileName" # delete the update file
_simpleTimer "5" # wait 5 seconds so user can read the output
}

## Looks for the latest release tag on GitHub and if there is a newer version available then it asks user for permission to download and update the script
_GIT_checkVersion() {
local _i; _i="$(_GIT_getInfo "repos/mi5hmash/SteamDeckBTRFS/releases/latest")"
local _v; _v="$(_GIT_getLatestVersion "$_i")"
local _t; _t="$(_isUpdateAvailable "$_v" "$TOOL_VERSION")"
case "$_t" in
	1) return;;
	2) ;;
	*) nickName="time traveller"; return;;
esac
_printUpdateMenu
if ! [ "$REPLY" = 1 ]; then return; fi
local _f; _f=$TOOL_NAME\_$_v$e_zip
local _d; _d="$(_GIT_getDownloadLink "$_i" "$_f")"
local _s; _s="./$TOOL_NAME.sh"
_GIT_update "$_d"
# Restore the execute permission
chmod u+x "$_s"
# Disable Update check on the next run
UPDATE_CHECK="0"
_writeSettingsJson
# Restart script
exec "$_s"
}

## Tries to download file from GitHub
# $1-GitHub path after raw/main/[...]; $2-Output File Path
_GIT_downloadFile() {
if [ "$INTERNET_CONNECTION" = "1" ]; then
	wget -q --show-progress -O "$2" -- "https://github.com/mi5hmash/SteamDeckBTRFS/raw/main/$1" &> /dev/null
fi
return "$?"
}

## Checks if the patch for a current system build is present in the 'patches' folder
## If not true then it tries to download a proper patch
_GIT_locatePatch() {
local _ret;
local _r; _r=1 # It looks like you have the patch for your current build '$s_BUILD' in the '$PatchPath' directory
local _fileName="$s_PATCH_CANDIDATE"
local _filePath="$PatchPath$_fileName"
# If _fileName is null then there is no patch anywhere.
if [ -z "$_fileName" ]; then
_r=3; # As for now there is no patch available for your current build
elif ! [ -e "$_filePath" ]; then
	_GIT_downloadFile "$_filePath" "$_filePath" # Try to download the patch file from GitHub
	_ret="$?"
	if [ "$_ret" = 0 ]; then
		_r=2 # The patch for your current build has been downloaded
	else
		rm -f "$_filePath"
		_r=3
	fi
fi
echo "$_r"
}

## On the basis of the scripts on the device, it determines whether the scripts have been patched and which patch will be appropriate
_specifyPatchCandidateAndState() {
local _a;
local _b;
local _c;
local _temp; _temp="_temp"
local _ret;
_a=$(_generateIntegrityHash "$SteamDeckFilesPath")
# Search for patch name in '_patches_own.csv' file
mkdir -p -- "$PatchPath"
_c="$PatchPath$n_patches_own$e_csv"
[ -e "$_c" ] && _b=$(grep "$_a" "$_c")
if [ -z "$_b" ]; then
# Search for patch name in '_patches.csv' file
_c="$PatchPath$n_patches$e_csv"
	if ! [ -e "$_c" ]; then
		_GIT_downloadFile "$_c" "$_c" # Try to download the latest '_patches.csv' from GitHub
		# Search for patch name in '_patches' dir
		[ -e "$_c" ] && _b=$(grep "$_a" "$_c")
	else
		_b=$(grep "$_a" "$_c")
		if [ -z "$_b" ]; then
			_GIT_downloadFile "$_c" "$_c$_temp"
			_ret="$?"
			if [ "$_ret" != 0 ]; then
				rm -f -- "$_c$_temp"
			else
				mv -f "$_c$_temp" "$_c"
				_b=$(grep "$_a" "$_c")
			fi
		fi
	fi
fi
if [ -n "$_b" ]; then
	mapfile -t -d ";" _c < <(echo -n "${_b}")
	s_PATCH_CANDIDATE="${_c[1]}$e_patch"
	s_PATCH_STATE="${_c[2]:0:1}"
fi
}

## Set script files adequate for current Steam OS build
_setScriptFiles() {
if [ "$(_isUpdateAvailable "20221221.1" "$s_BUILD")" -eq 2 ]; then
	ScriptFiles=("sdcard-mount.sh" "format-sdcard.sh")
elif [ "$(_isUpdateAvailable "20231116.2" "$s_BUILD")" -eq 2 ]; then
	ScriptFiles=("sdcard-mount.sh" "format-device.sh")
else
	ScriptFiles=("steamos-automount.sh")
fi
}


### MENUS

_sayHello() {
local _i; _i="$(date +%H)" # Get the current hour
local _a=", $nickName! \(^-^)/"
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
local _a=", $nickName! (^-^)"
if [ "$_i" -ge 5 ] && [ "$_i" -lt 12 ]; then
	echo "Have a great day$_a"
elif [ "$_i" -ge 12 ] && [ "$_i" -lt 18 ]; then
	echo "Enjoy your afternoon$_a"
else
	echo "Good night$_a"
fi
}

## Title Banner
_printTitle() {
local _l=64
echo -e "$clr1$(sayp "-*" $_l)$clr0"
echo -e "$clr1"" ___ _                  ___         _   ""\e[5;95m"" ___ _____ ___  ___ ___ ""$clr0"
echo -e "$clr1""/ __| |_ ___ __ _ _ __ |   \ ___ __| |_ ""\e[5;95m""| _ )_   _| _ \| __/ __|""$clr0"
echo -e "$clr1""\__ \  _/ -_) _\` | '  \| |) / -_) _| / /""\e[5;95m""| _ \ | | |   /| _|\__ \\""\\$clr0"
echo -e "$clr1""|___/\__\___\__,_|_|_|_|___/\___\__|_\_\\""\\\e[5;95m""|___/ |_| |_|_\|_| |___/""$clr0"
echo -e "$clr1""$(sayr "patcher by Mi5hmasH $clr2""$TOOL_VERSION" $_l)""$clr0"
echo -e "$clr1$(sayp "*-" $_l)$clr0"
echo -e "$clr1$(say "=" $_l)$clr0"
echo -e "$clr2""$(saym "PATCH, BACKUP or RESTORE SteamDeck's sdcard related scripts" $_l)""$clr0"
echo -e "$clr2""$(saym "Make your SteamDeck friendly with btrfs formatted sdcards" $_l)""$clr0"
echo -e "$clr1$(say "=" $_l)$clr0"
echo -e "$clr2""$(saym "Based on Trevo525's 'btrfdeck' repository" $_l)""$clr0"
echo -e "$clr2""$(saym "https://github.com/Trevo525/btrfdeck" $_l)""$clr0"
echo -e "$clr1$(say "=" $_l)$clr0"
echo -e "$clr2""My repo: $git_link""$clr0"
echo -e "$clr1$(say "=" $_l)$clr0"
_printOsInfo
echo -e "$clr1$(say "=" $_l)$clr0"
_printPatchAvailabilityStatus
echo -e "$clr1$(say "=" $_l)$clr0"
}

## Print HiddenOptions
_printHiddenOptions() {
echo "97) Toggle steamos-readonly status"
echo "98) Prepare a workbench"
echo "99) Create a patch file"
}

## Main Menu
_printMainMenu() {
PS3=$ps3_1 # Set the Select Prompt (PS3)
REPLY=0 # default reply
local _t; _t=$([ "$s_PATCH_STATE" == "P" ] && echo "Unpatch scripts" || echo "Patch scripts")
local _opts=("$_t" "Backup scripts" "Restore backupped scripts")
[ "$FIRST_LAP" = 1 ] &&
echo -e "$(_sayHello)\nHow may I help you?\n$(say "-" 19)" ||
echo -e "What else can I do for you? (^-^)\n$(say "-" 33)"
echo "0) Exit"
[ "$SHOW_HIDDEN_OPTIONS" = "1" ] && echo -e "$(_printHiddenOptions)"
COLUMNS=1
select _ in "${_opts[@]}"; do
	case "$REPLY" in
		# Un/Patch scripts
		1) checkSudo; if [ "$s_PATCH_STATE" == "P" ]; then unpatchScripts; else patchScripts; fi; sudoTaskFinalize; break;;
		# Backup scripts
		2) backupScripts; break;;
		# Restore backupped scripts
		3) checkSudo; restoreBackup; sudoTaskFinalize; break;;
		# EXIT
		0) _exit;;
		## HIDDEN OPTIONS
		# steamos-readonly toggle
		97) checkSudo; steamOsReadOnlyToggle; sudoTaskFinalize; break;;
		# Prepare a workbench
		98) echo; chooseBackup; break;;
		# Create a patch file
		99) echo; createPatchFile; break;;
		# Default option
		*) echo_W "Sorry, but I have only ${#_opts[@]} tasks programmed. Please, select a number from a list.";;
	esac
done
}

## Are We Done Menu
_printAreWeDoneMenu() {
PS3=$ps3_1
local _s; _s="Are we done?"
echo "$_s"
echo -e "$(say "-" ${#_s})"
REPLY=1 # default reply
COLUMNS=1
select _ in "Yes" "No"; do
	case $REPLY in
		1|Y|y|Yes|yes) _exit;;
		2|N|n|No|no) FIRST_LAP=0; break;;
		*) echo_W "Sorry, but you have to choose between 'Yes' and 'No' options.";;
	esac
done
}

## Download and Update Menu
_printUpdateMenu() {
PS3=$ps3_1
local _s; _s="There is a newer version available! Would you like to update?"
echo "$_s"
echo -e "$(say "-" ${#_s})"
REPLY=1 # default reply
COLUMNS=1
select _ in "Yes" "No"; do
	case $REPLY in
		1|Y|y|Yes|yes) REPLY=1; break;;
		2|N|n|No|no) REPLY=2; break;;
		*) echo_W "Sorry, but you have to choose between 'Yes' and 'No' options.";;
	esac
done
}

## SELECT Backup to Restore
_pritnSelectBackupFileMenu() {
PS3=$ps3_1
REPLY=0 # default reply
mkdir -p -- "$BackupPath"
local _opts; readarray -t _opts < <( find "./$BackupPath" -iname "*$e_backup" -exec basename {} \; )
if [ ${#_opts[@]} -gt 0 ]; then
	local _s; _s="Please, select a backup file which you would like to $1"
	echo -e "$_s"
	echo -e "$(say - ${#_s})"
	echo "0) Exit to the previous menu"
	COLUMNS=1
	local _o; select _o in "${_opts[@]}"
	do
		[ "$REPLY" = 0 ] && break
		[ "$REPLY" -le ${#_opts[@]} ] && [ "$REPLY" -gt 0 ] && echo_I "File '$_o' has been selected." && REPLY="${_opts[$REPLY-1]}" && break
		echo "Unfortunately, there is no file assigned to '$REPLY' option. Please, pick a number from a list of available files."
	done
else
	echo_E "It seems there is no single '*$e_backup' file in the '$BackupPath' directory. Please, first put a proper backup in there and then try again."
fi
}

restoreBackup() {
_pritnSelectBackupFileMenu "restore:"
# Call restoreScripts function
[ "$REPLY" = 0 ] || restoreScripts "$REPLY"
}

chooseBackup() {
_pritnSelectBackupFileMenu "use:"
# Call _prepareWorkbench function
[ "$REPLY" = 0 ] || _prepareWorkbench "$REPLY"
}

_printOsInfo() {
echo -ne "$clr1$s_NAME $s_VERSION\t\e[1;93m$s_BUILD\t$clr2$s_VARIANT\t$(_sudoStatusText)\t$(_steamOsReadOnlyStatusBTRFS 1)$clr0" | column -s '	' -t -N "OS:,Build:,Variant:,Sudo Status:,ReadOnly:"
}

_printPatchAvailabilityStatus() {
local _s
local _a="PATCHED"
local _s2;
case "$s_PATCH_STATE" in
	"P") _s2="\e[1;96m$_a$clr0";;
	"O") _s2="\e[1;31mUN$_a$clr0";;
	*) _s2="\e[1;93m$(echo "$unknown" | tr "[:lower:]" "[:upper:]")$clr0";;
esac
local _i=$s_PATCH_AVAILABILITY
if [ "$_i" = 0 ]; then return; fi
case "$_i" in
	1) _s="\e[1;96mPRESENT$clr0";;
	2) _s="\e[1;96mDOWNLOADED$clr0";;
	3) _s="\e[1;31mNOT AVAILABLE$clr0";;
esac
echo -e "SCRIPTS STATUS: $_s2 | PATCH FILE: $_s"
}

_exit() {
PS3="#?" # Restore the default Select Prompt (PS3)
echo -e "\nExiting...\n$(_sayGoodbye)"
echo_I "You can safely close this window now."; exit
}


### GLOBAL VARIABLES

## MAIN VARIABLES
SESSION_GUID="$(uuidgen | tr "[:lower:]" "[:upper:]")"; readonly SESSION_GUID
ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd); readonly ROOT_DIR
declare -r TOOL_NAME="SteamDeckBTRFS"
declare -r TOOL_VERSION="v2.0.9"
declare -ri PACKAGE_VERSION="102"
declare -r unknown="unknown"
declare -r ps3_1="Enter the number of your choice: "
declare -r git_link="https://github.com/mi5hmash/$TOOL_NAME"

## Username and temporary password
userName="$USER" # real username (deck)
nickName="$USER" # for the greetings funcs
declare -r tempPasswd="GabeNewell#1"

## OS INFO
s_NAME=$(_getSettingsValue "NAME"); readonly s_NAME
s_VERSION=$(_getSettingsValue "VERSION_ID"); readonly s_VERSION
s_VARIANT=$(_getSettingsValue "VARIANT_ID"); readonly s_VARIANT
s_BUILD=$(_getSettingsValue "BUILD_ID"); readonly s_BUILD
s_ROOTFS_TYPE=$(findmnt -fn --output FSTYPE /); readonly s_ROOTFS_TYPE

## PATCH INFO
s_PATCH_AVAILABILITY=0;
s_PATCH_CANDIDATE="";
s_PATCH_STATE="";

## FLAGS
FIRST_LAP=1
INTERNET_CONNECTION="$(_testConnection && echo 1 || echo 0)"
DEF_RO_STATUS=$(_steamOsReadOnlyStatusBTRFS)
DEF_USR_HAS_PASSWD=$(_userHasPassword "$userName" && echo 1 || echo 0); readonly DEF_USR_HAS_PASSWD
PACMAN_REFRESHED=0

## PATHS
declare -r UserSecPath="./.user.sec"
declare -r OriginalFilesIntelPath="./org_intel/"
declare -r OriginalFilesPath="./original/"
declare -r PatchedFilesPath="./patched/"
declare -r BackupPath="./backup/"
declare -r PatchPath="./patches/"
declare -r TempPath="./.temp/"
declare -r WorkbenchPath="./workbench/"
declare -r SteamDeckFilesPath="/usr/lib/hwsupport/"

## FILENAMES & EXTENSIONS
declare ScriptFiles; _setScriptFiles; readonly ScriptFiles
declare -r n_build="build"
declare -r n_version="version"
declare -r n_chmod="chmod"
declare -r n_checksums_o="checksums_o"
declare -r n_checksums_p="checksums_p"
declare -r n_patch="btrfsPatch"
declare -r n_patches="_patches"
declare -r n_patches_own="_patches_own"
declare -r e_patch=".patch"
declare -r e_zip=".zip"
declare -r e_backup=".backup"
declare -r e_csv=".csv"
declare -r e_unpatch=".unpatch"


### SETTINGS

declare -r settingsJson="settings.json" # Settings fileName
declare -r settingsNames=("UPDATE_CHECK" "SHOW_HIDDEN_OPTIONS" "SEC_KEY" "REMEMBER_PASSWORD") # Settings Names
declare -r settingsFormats=("i" "i" "s" "i") # Settings Formats (i - integer; s - string)
declare -r settingsDefaults=("1" "0" "$(_randomPasswordGen "32")" "0") # Settings Default Values

## Reads settings from a 'settingsJson' config file
_readSettingsJson() {
_jq() { jq -r ".$1" "$settingsJson"; }
local _t;
# Settings to read
for (( i=0; i<"${#settingsNames[@]}"; i++ ))
do
	_t="$(_jq "${settingsNames[$i]}")"
	_t=$([ -z "$_t" ] || [ "$_t" = "null" ] && echo "${settingsDefaults[$i]}" || echo "$_t")
	printf -v "${settingsNames[$i]}" -- "%${settingsFormats[$i]}" "$_t"
done
}

## Writes settings to a 'settingsJson' config file
_writeSettingsJson() {
local _n;
local _q;
# Settings to write
for (( i=0; i<"${#settingsNames[@]}"; i++ ))
do
	_n=${settingsNames[$i]}
	[ "$i" -gt 0 ] && _q="$_q | "
	_q="$_q.$_n=\"${!_n}\""
done
jq -n "$_q" > "$settingsJson";
}

## Loads Settings from an existing 'settingsJson' config file or creates a new one
loadSettingsJson() {
local _s="$settingsJson"
if ! [ -e "./$_s" ]; then
	touch "$_s"
	_readSettingsJson # in this case it sets the default settings
	_writeSettingsJson # write new settings file
else
	_readSettingsJson # load settings from the existing file
fi
}


### MAIN (ENTRY POINT)

echo "Loading..."

## Check sudo
if [ "$(_sudoStatus)" = 0 ]; then
	clear
	echo_E "Sorry, but it seems that a current user hasn't got root rights. Please, contact the adminstrator of your device.\n"
	exit
fi
loadSettingsJson ## Load Settings
## Update
cd -- "$ROOT_DIR" || return
if [ "$UPDATE_CHECK" = "1" ]; then
	clear
	[ "$INTERNET_CONNECTION" = "1" ] && echo_I "Checking for updates..." && _GIT_checkVersion
else
	UPDATE_CHECK="1"
fi
_writeSettingsJson ## Save Settings
_specifyPatchCandidateAndState
s_PATCH_AVAILABILITY="$(_GIT_locatePatch)"
_setPassword "$( ([ -e $UserSecPath ] && "_readUserSec") || echo "$tempPasswd" )"
## Main Menu Loop
while true
do
	cd -- "$ROOT_DIR" || return
	clear
	_printTitle
	echo
	_printMainMenu
	echo
	_printAreWeDoneMenu
done