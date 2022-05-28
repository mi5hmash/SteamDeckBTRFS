#!/bin/bash

### STYLES
clr0="\e[0m"; clr1="\e[1;94m"; clr2="\e[1;95m"
echo_E() { echo -e "\e[1;31m[ERROR] $1$clr0"; }
echo_S() { echo -e "\e[1;96m[SUCCESS] $1$clr0"; }
echo_W() { echo -e "\e[1;93m[WARNING] $1$clr0"; }
echo_I() { echo -e "\e[1;34m[INFO] $1$clr0"; }


### FUNCTIONS

## Repeat input string n times
# $1-Input string; $2-Times
say() { for _ in $(seq 1 "${2:-1}"); do echo -n "$1"; done; }

## Get password variable
_getPassword() { _decrypt "$passWord"; }
## Set password variable
_setPassword() { passWord=$(_encrypt "$1"); }

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
echo "$1" | openssl enc -aes-256-cbc -md sha512 -a -pbkdf2 -iter 100000 -salt -pass "pass:$SESSION_GUID"
}
_decrypt() {
echo "$1" | openssl enc -aes-256-cbc -md sha512 -a -d -pbkdf2 -iter 100000 -salt -pass "pass:$SESSION_GUID"
}

## Read password from user input if it does have one set
_readExistingUserPassword() {
local _p; _p=$(_getPassword)
local _f=0 # helps to omit the encryption on the first try (when the script tries out a default password)
while true; do
	# if given password is valid then encrypt it
	if [ "$(_validateSudoPassword "$_p")" = 1 ]; then
		[ $_f = 1 ] && _setPassword "$_p"
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

## Restores SteamOsReadOnly status if needed and removes user password if user doesn't have one set on script launch
_sudoTaskFinalize() {
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

## Pokes a hidden 'steamos-readonly' function which toggles readonly status
_steamOsReadOnlyToggle() {
local _c # color
local _s; _s="$(sudo steamos-readonly toggle)" # status
[ "$_s" = "enabled" ] && _c="\e[1;96m" || _c="\e[1;31m"
echo -e "SteamOS filesystem readonly is now $_c$_s$clr0."
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


### BACKUP

## Backup scripts from SteamDeck
backupScripts() {
local _timestamp; _timestamp="$(_createTimestamp "")"
local _backup="$s_BUILD$_timestamp.backup"
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
rm -vrf -- "$TempPath" &> /dev/null
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
	4:7) echo_E "{$_err} Backup has been made with a newer version ($_tempDir$n_version) of $tool_name tool. Please download the newest version from: $git_link/releases";;
	4:8) echo_E "$_errb on unpacking.";;
	*) echo_E "$_errb.";;
esac
# Remove directory
rm -vrf -- "$TempPath" &> /dev/null
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
local _patch="$s_BUILD$e_patch"
mkdir -p -- "$_tempDir" "$PatchPath"
echo_I "Searching for a patch..."
([ -e "$PatchPath$_patch" ] || exit 3
echo_S "Patch file found."
echo_I "Trying to unpack..." # Unpack
tar -xzf "$PatchPath$_patch" -C "$_tempDir" || exit 8
echo_S "Patch upacked."
echo_I "Verifying checksums..." # Verify sha256 checksums
_dirSHA256sumRW "$SteamDeckFilesPath" "$_tempDir$n_checksums_o" 1 || exit 4
echo_S "Files checksums verified."
echo_I "Trying to patch..."
sudo patch --dry-run -fruN -d "$SteamDeckFilesPath" < <(zcat "$_tempDir$n_patch$e_patch") || exit 7
sudo patch -fruN -d "$SteamDeckFilesPath" < <(zcat "$_tempDir$n_patch$e_patch"))
local _err="1:$?"
local _errb="{$_err} Patching script files has failed"
case "$_err" in
	1:0) echo_S "Scripts files on your SteamDeck has been patched.";;
	1:3) echo_E "{$_err} There is no patch file for your current build '$s_BUILD' in the '$PatchPath' directory.";;
	1:4) echo_E "{$_err} Files' checksums don't match.";;
	*) echo_E "$_errb.";;
esac
# Remove directory
rm -vrf -- "$TempPath" &> /dev/null
}

unpatchScripts() {
local _tempDir="$TempPath$s_BUILD/"
local _patch="$s_BUILD$e_patch"
mkdir -p -- "$_tempDir" "$PatchPath"
echo_I "Searching for a patch..."
([ -e "$PatchPath$_patch" ] || exit 3
echo_S "Patch file found."
echo_I "Trying to unpack..." # Unpack
tar -xzf "$PatchPath$_patch" -C "$_tempDir" || exit 8
echo_S "Patch upacked."
echo_I "Verifying checksums..." # Verify sha256 checksums
_dirSHA256sumRW "$SteamDeckFilesPath" "$_tempDir$n_checksums_p" 1 || exit 4
echo_S "Files checksums verified."
echo_I "Trying to unpatch..."
sudo patch --dry-run --ignore-whitespace -ruN -d "$SteamDeckFilesPath" < <(zcat "$_tempDir$n_patch$e_unpatch") || exit 7
sudo patch -ruN --ignore-whitespace -d "$SteamDeckFilesPath" < <(zcat "$_tempDir$n_patch$e_unpatch"))
local _err="2:$?"
local _errb="{$_err} Unpatching script files has failed"
case "$_err" in
	2:0) echo_S "Scripts files on your SteamDeck has been unpatched.";;
	2:3) echo_E "{$_err} There is no patch file for your current build '$s_BUILD' in the '$PatchPath' directory.";;
	2:4) echo_E "{$_err} Files' checksums don't match.";;
	*) echo_E "$_errb.";;
esac
# Remove directory
rm -vrf -- "$TempPath" &> /dev/null
}

## Prepares Workspace to manually patch the files
# $1-Backup File Name
_prepareWorkspace() {
local _backup="$1"
mkdir -p -- "$OriginalFilesPath" "$PatchedFilesPath"
echo_I "Unpacking the backup archieve..." # Unpack
(tar -xzf "$BackupPath$_backup" -C "$OriginalFilesPath" || exit 8
echo_I "Verifying checksums..." # Verify sha256 checksums
_dirSHA256sumRW "$OriginalFilesPath" "$OriginalFilesPath$n_checksums_o" 1 || exit 4
# Copy scripts
echo_I "Copying files..."
for f in "${ScriptFiles[@]}"
do
	cp -f "$OriginalFilesPath$f" "$PatchedFilesPath$f" &> /dev/null || exit 3
done )
local _err="98:$?"
local _errb="{$_err} Creating a workspace has failed"
case "$_err" in
	98:0) echo_S "Scripts from a backup file '$_backup' has been unpacked to '$OriginalFilesPath' and '$PatchedFilesPath'.";;
	98:3) echo_E "$_errb on copying files";;
	98:4) echo_E "$_errb on veryfying";;
	98:8) echo_E "$_errb on unpacking";;
	*) echo_E "$_errb.";;
esac
}

createPatchFile() {
local _tempDir="$TempPath$s_BUILD/"
local _patch="$s_BUILD$e_patch"
mkdir -p -- "$_tempDir" "$PatchPath"
# Create a real patch and unpatch files, compressed with gzip compression level 9
# More info about creating patches: https://www.howtogeek.com/415442/how-to-apply-a-patch-to-a-file-and-create-patches-in-linux/
echo_I "Comparing files..."
(diff -ruN "$OriginalFilesPath" "$PatchedFilesPath" | gzip -9 > "$_tempDir$n_patch$e_patch"
[ "${PIPESTATUS[0]}" -le 1 ] || exit 3
echo_S "Patch file created."
diff -ruN "$PatchedFilesPath" "$OriginalFilesPath" | gzip -9 > "$_tempDir$n_patch$e_unpatch"
[ "${PIPESTATUS[0]}" -le 1 ] || exit 3
echo_S "Reverse patch file created."
# Create file with sha256 checksums
_dirSHA256sumRW "$OriginalFilesPath" "$_tempDir$n_checksums_o" || exit 4
_dirSHA256sumRW "$PatchedFilesPath" "$_tempDir$n_checksums_p" || exit 5
echo_S "Files with checksums created."
# Create 'build' file
echo_I "Collecting info about SteamOS build and tool version..."
echo "$s_BUILD" > "$_tempDir$n_build" || exit 6
# Create 'version' file
echo "$PACKAGE_VERSION" > "$_tempDir$n_version" || exit 7
echo_S "Info about build and version collected."
# Pack all files with a fake *.patch extension
echo_I "Trying to pack..."
_tarPack "$_tempDir" "$PatchPath$s_BUILD$e_patch" || exit 8)
local _err="99:$?"
local _errb="{$_err} Creating a patch file has failed"
case "$_err" in
	99:0) echo_S "Patch file '$_patch' has been created in the '$PatchPath' directory.";;
	99:7) echo_E "$_errb on packing.";;
	*) echo_E "$_errb.";;
esac
# Remove directory
rm -vrf -- "$TempPath" &> /dev/null
}

## Calculate SHA256 checksums of files in directory
# $1-Intput File Path; $2-Output File Path; if $3 not null then read instead of write;
_dirSHA256sumRW() {
local _s=1 #status - preassume function failure
cd -- "$1" || return
if [ -z "$3" ]; then
	sha256sum -b -- * > "$OLDPWD/$2"
else	
	sha256sum --status -c -- "$OLDPWD/$2"
fi
_s=$?
cd -- "$OLDPWD" || return
[ "$_s" = 0 ]
}

## Backup Chmod
# $1-Root Directory of a File Collection; $2-Output File Path; if $3 not null then delete old file;
_backupChmod() {
# Delete previous file if exist
[ -n "$3" ] && rm -vf -- "$2" &> /dev/null
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
tar -cf - * | gzip -9 > "$OLDPWD/$2"
_s=${PIPESTATUS[0]}
cd -- "$OLDPWD" || return
[ "$_s" = 0 ]
}


### MENUS

_sayHello() {
local _i; _i="$(date +%H)" # Get the current hour
local _a=", $USER! \(^-^)/"
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
local _a=", $USER! (^-^)"
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
echo -e "$clr1$(say "-*" 32)$clr0"
echo -e "$clr1"" ___ _                  ___         _   ""\e[5;95m"" ___ _____ ___  ___ ___ ""$clr0"
echo -e "$clr1""/ __| |_ ___ __ _ _ __ |   \ ___ __| |_ ""\e[5;95m""| _ )_   _| _ \| __/ __|""$clr0"
echo -e "$clr1""\__ \  _/ -_) _\` | '  \| |) / -_) _| / /""\e[5;95m""| _ \ | | |   /| _|\__ \\""\\$clr0"
echo -e "$clr1""|___/\__\___\__,_|_|_|_|___/\___\__|_\_\\""\\\e[5;95m""|___/ |_| |_|_\|_| |___/""$clr0"
echo -e "$clr1""$(say " " 39)patcher by Mi5hmasH ""$clr2""v$TOOL_VERSION""$clr0"
echo -e "$clr1$(say "*-" 32)$clr0"
echo -e "$clr1$(say "=" 64)$clr0"
echo -e "$clr2""  PATCH, BACKUP or RESTORE SteamDeck's sdcard related scripts   ""$clr0"
echo -e "$clr2""   Make your SteamDeck friendly with btrfs formatted sdcards    ""$clr0"
echo -e "$clr1$(say "=" 64)$clr0"
echo -e "$clr2""           Based on Trevo525's 'btrfdeck' repository            ""$clr0"
echo -e "$clr2""              https://github.com/Trevo525/btrfdeck              ""$clr0"
echo -e "$clr1$(say "=" 64)$clr0"
echo -e "$clr2""My repo: $git_link             ""$clr0"
echo -e "$clr1$(say "=" 64)$clr0"
_printOsInfo
echo -e "$clr1$(say "=" 64)$clr0"
}

## Main Menu
_printMainMenu() {
PS3=$ps3_1 # Set the Select Prompt (PS3)
REPLY=0 # default reply
local _opts=("Patch scripts" "Unpatch scripts" "Backup scripts" "Restore backupped scripts")
[ "$FIRST_TIME" = 1 ] &&
echo -e "$(_sayHello)\nHow may I help you?\n$(say "-" 19)" ||
echo -e "What else can I do for you? (^-^)\n$(say "-" 33)"
echo "0) Exit"
COLUMNS=1
select _ in "${_opts[@]}"
do
	case "$REPLY" in
		# Patch scripts
		1) checkSudo; patchScripts; _sudoTaskFinalize; break;;
		# Unpatch scripts
		2) checkSudo; unpatchScripts; _sudoTaskFinalize; break;;
		# Backup scripts
		3) backupScripts; break;;
		# Restore backupped scripts
		4) checkSudo; restoreBackup; _sudoTaskFinalize; break;;
		# EXIT
		0) _exit;;
		## HIDDEN OPTIONS
		# steamos-readonly toggle
		97) checkSudo; _steamOsReadOnlyToggle; DEF_RO_STATUS=$(_steamOsReadOnlyStatusBTRFS); _sudoTaskFinalize; break;;
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
echo "Are we done?"
echo "------------"
REPLY=1 # default reply
COLUMNS=1
select _ in "Yes" "No"; do
	case $REPLY in
		1|Y|y|Yes|yes) _exit;;
		2|N|n|No|no) FIRST_TIME=0; break;;
		*) echo_W "Sorry, but you have to choose between 'Yes' and 'No' options.";;
	esac
done
}

## SELECT Backup to Restore
_pritnSelectBackupFileMenu() {
PS3=$ps3_1
REPLY=0 # default reply
mkdir -p -- "$BackupPath"
local _opts; readarray -t _opts < <( find "./$BackupPath" -iname "*.backup" -exec basename {} \; )
if [ ${#_opts[@]} -gt 0 ]; then
	echo -e "Please, select a backup file which you would like to $1"
	echo "0) Exit to the previous menu"
	COLUMNS=1
	local _o; select _o in "${_opts[@]}"
	do
		[ "$REPLY" = 0 ] && break
		[ "$REPLY" -le ${#_opts[@]} ] && [ "$REPLY" -gt 0 ] && echo_I "File '$_o' has been selected." && REPLY="${_opts[$REPLY-1]}" && break
		echo "Unfortunately, there is no file assigned to '$REPLY' option. Please, pick a number from a list of available files."
	done
else
	echo_E "It seems there is no single '*.backup' file in the '$BackupPath' directory. Please, first put a proper backup in there and then try again."
fi
}

restoreBackup() {
_pritnSelectBackupFileMenu "restore:\n$(say - 61)"
# Call restoreScripts function
[ "$REPLY" = 0 ] || restoreScripts "$REPLY"
}

chooseBackup() {
_pritnSelectBackupFileMenu "use:\n$(say - 57)"
# Call _prepareWorkspace function
[ "$REPLY" = 0 ] || _prepareWorkspace "$REPLY"
}

_printOsInfo() {
echo -ne "$clr1$s_NAME $s_VERSION\t\e[1;93m$s_BUILD\t$clr2$s_VARIANT\t$(_sudoStatusText)\t$(_steamOsReadOnlyStatusBTRFS 1)$clr0" | column -s '	' -t -N "OS:,Build:,Variant:,Sudo Status:,ReadOnly:"
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
declare -r TOOL_VERSION="1.00"
declare -ri PACKAGE_VERSION=${TOOL_VERSION//./}
declare -r unknown="unknown"
declare -r ps3_1="Enter the number of your choice: "
declare -r tool_name="SteamDeckBTRFS"
declare -r git_link="https://github.com/mi5hmash/SteamDeckBTRFS"

## Username and temporary password
userName="$USER" # deck
_setPassword "GabeNewell#1" # default password

## OS INFO
s_NAME=$(_getSettingsValue "NAME"); readonly s_NAME
s_VERSION=$(_getSettingsValue "VERSION_ID"); readonly s_VERSION
s_VARIANT=$(_getSettingsValue "VARIANT_ID"); readonly s_VARIANT
s_BUILD=$(_getSettingsValue "BUILD_ID"); readonly s_BUILD
s_ROOTFS_TYPE=$(findmnt -fn --output FSTYPE /); readonly s_ROOTFS_TYPE

## FLAGS
FIRST_TIME=1
DEF_RO_STATUS=$(_steamOsReadOnlyStatusBTRFS)
DEF_USR_HAS_PASSWD=$(_userHasPassword "$userName" && echo 1 || echo 0); readonly DEF_USR_HAS_PASSWD

## PATHS
declare -r OriginalFilesPath="./original/"
declare -r PatchedFilesPath="./patched/"
declare -r BackupPath="./backup/"
declare -r PatchPath="./patches/"
declare -r TempPath="./.temp/"
declare -r SteamDeckFilesPath="/usr/lib/hwsupport/"

## FILENAMES & EXTENSIONS
declare -r ScriptFiles=("sdcard-mount.sh" "format-sdcard.sh")
declare -r n_build="build"
declare -r n_version="version"
declare -r n_chmod="chmod"
declare -r n_checksums_o="checksums_o"
declare -r n_checksums_p="checksums_p"
declare -r n_patch="btrfsPatch"
declare -r e_patch=".patch"
declare -r e_unpatch=".unpatch"


### MAIN (ENTRY POINT)
if [ "$(_sudoStatus)" = 0 ]; then
	clear
	_printTitle
	echo
	echo_E "Sorry, but it seems that a current user hasn't got root rights. Please, contact the adminstrator of your device.\n"
	exit
fi
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