[![License: MIT](https://img.shields.io/badge/License-MIT-blueviolet.svg)](https://opensource.org/licenses/MIT)
[![Release Version](https://img.shields.io/github/v/tag/mi5hmash/SteamDeckBTRFS?label=Tool%20Version)](https://github.com/mi5hmash/SteamDeckBTRFS/releases/latest)
[![Latest Supported SteamOS](https://img.shields.io/badge/Latest%20Supported%20SteamOS-v3.6.22%20--%20build%2020250224.1-seagreen)](#)
[![Visual Studio Code](https://custom-icon-badges.demolab.com/badge/Visual%20Studio%20Code-0078d7.svg?logo=vsc&logoColor=white)](https://code.visualstudio.com/)

> [!IMPORTANT]
> **Scripts from this repo are free and open source. If someone asks you to pay for them, it's likely a scam.**

## SteamOS Branches & Versions:
[![SteamOS Branch Version: Stable](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fsteamdeck-atomupd.steamos.cloud%2Fmeta%2Fsteamos%2Famd64%2Fsnapshot%2Fsteamdeck.json&query=%24..candidates%5B0%5D.image.version&prefix=v&label=stable&color=teal)](#)
[![SteamOS Branch Version: Release Candidate](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fsteamdeck-atomupd.steamos.cloud%2Fmeta%2Fsteamos%2Famd64%2Fsnapshot%2Fsteamdeck-rc.json&query=%24..candidates%5B0%5D.image.version&prefix=v&label=release%20candidate&color=00b3b3)](#)

[![SteamOS Branch Version: Preview](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fsteamdeck-atomupd.steamos.cloud%2Fmeta%2Fsteamos%2Famd64%2Fsnapshot%2Fsteamdeck-preview.json&query=%24..candidates%5B0%5D.image.version&prefix=v&label=preview&color=teal)](#)
[![SteamOS Branch Version: Preview Candidate](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fsteamdeck-atomupd.steamos.cloud%2Fmeta%2Fsteamos%2Famd64%2Fsnapshot%2Fsteamdeck-pc.json&query=%24..candidates%5B0%5D.image.version&prefix=v&label=preview%20candidate&color=00b3b3)](#)

[![SteamOS Branch Version: Beta](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fsteamdeck-atomupd.steamos.cloud%2Fmeta%2Fsteamos%2Famd64%2Fsnapshot%2Fsteamdeck-beta.json&query=%24..candidates%5B0%5D.image.version&prefix=v&label=beta&color=teal)](#)
[![SteamOS Branch Version: Beta Candidate](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fsteamdeck-atomupd.steamos.cloud%2Fmeta%2Fsteamos%2Famd64%2Fsnapshot%2Fsteamdeck-bc.json&query=%24..candidates%5B0%5D.image.version&prefix=v&label=beta%20candidate&color=00b3b3)](#)

[![SteamOS Branch Version: Main](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fsteamdeck-atomupd.steamos.cloud%2Fmeta%2Fsteamos%2Famd64%2Fsnapshot%2Fsteamdeck-main.json&query=%24..candidates%5B0%5D.image.version&prefix=v&label=main&color=004d4d)](#)
[![SteamOS Branch Version: Staging](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fsteamdeck-atomupd.steamos.cloud%2Fmeta%2Fsteamos%2Famd64%2Fsnapshot%2Fsteamdeck-staging.json&query=%24..candidates%5B0%5D.image.version&prefix=v&label=staging&color=004d4d)](#)
[![SteamOS Branch Version: Galileo](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fsteamdeck-atomupd.steamos.cloud%2Fmeta%2Fsteamos%2Famd64%2Fsnapshot%2Fsteamdeck-galileo.json&query=%24..candidates%5B0%5D.image.version&prefix=v&label=galileo&color=004d4d)](#)

# :interrobang: SteamDeckBTRFS - What is it?
<p float="left">
  <img src="https://github.com/mi5hmash/SteamDeckBTRFS/blob/main/.resources/images/cover.png" alt="cover" width="460" />
  <img src="https://github.com/mi5hmash/SteamDeckBTRFS/blob/main/.resources/images/iconart.png" alt="icon" width="256" />
</p>

It's a shell script for lazy people like me who want to use [BTRFS](https://btrfs.wiki.kernel.org/index.php/Main_Page) formatted microSD cards on their decks, but don't want to type many commands into a command line. If you're one of us, worry no more as I got you covered.

**Despite that it's simple, you're still <mark>using it at your own risk</mark>. I've tried my best to make it foolproof and always run tests before release until I consider it stable, but some things may show up only after long use. You've been warned.**
# :tipping_hand_person: Yet another repository? | How is it different?
There are other repositories like mine. They are based on replacing entire scripts with the ones already patched. My approach is to **patch the original scripts directly** using a small patch file. My tool also lets you **perform a reverse patch (unpatch)** operation on the patched scripts or **create a backup** of the original scripts so they can be restored later (**restore backup**).
# :performing_arts: Pros and cons
Everything has been well explained in the 
[btrfdeck repository](https://github.com/Trevo525/btrfdeck) by [Trevo525](https://github.com/Trevo525). Instead of copy-pasting everything from there here and thus committing plagiarism, I will just encourage you to go there and read the original content of that repo.
# 🧑‍🔧 Installing the script
There are two ways to install this tool: Automatic or Manual [PRO].

### A) Automatic installation
The automatic installation script will download and install the latest version of this tool in the ***'DOCUMENTS'*** directory and create a shortcut on ***'DESKTOP'***.

To install this way, open a new Konsole window and paste one of the following lines of code depending on what you want to do:
#### Install
```bash
curl -sSL https://raw.githubusercontent.com/mi5hmash/SteamDeckBTRFS/main/_Installer.sh | bash
```

#### Uninstall
```bash
curl -sSL https://raw.githubusercontent.com/mi5hmash/SteamDeckBTRFS/main/_Installer.sh | bash -s -- -u
```
### B) Manual installation
Grab the [latest release](https://github.com/mi5hmash/SteamDeckBTRFS/releases/latest) and unpack it on your Steam Deck.
Then right-click on the ***'_Create a Shortcut on Desktop.sh'*** and select *"Properties"*. Navigate to the "Permissions" tab and make sure that an "Is executable" checkbox is ticked.

<img src="https://github.com/mi5hmash/SteamDeckBTRFS/blob/main/.resources/images/permissions.png" alt="permissions" width="415"/>

Then click **OK** and once again right-click on the ***'_Create a Shortcut on Desktop'***, but this time select *"Run in Konsole"*.
You can also click twice and execute that script. 

<img src="https://github.com/mi5hmash/SteamDeckBTRFS/blob/main/.resources/images/run.png" alt="run" width="415"/>

A desktop shortcut will be created.

<img src="https://github.com/mi5hmash/SteamDeckBTRFS/blob/main/.resources/images/desktop_icon.png" alt="desktop_icon" width="280"/>

# :runner: Running the script
Regardless of which installation method you choose, you should end up with a shortcut on your desktop. Run the script with it.

**Do not attempt to execute 'SteamDeckBTRFS.sh' by clicking twice on it, because this will run the script in a hidden window.**

**Do not click on 'Add to Steam' and try to execute 'SteamDeckBTRFS.sh' from the Gaming Mode. It's meant to be run from the desktop.**

# :alarm_clock: Updating the tool and getting the latest patch
Starting from version 1.1.0, the script checks on each launch if a newer release is available. If so, it asks the user for permission to download and update the tool. 
Next, the script will check if there is a patch for the current build of the system in the ***"./patches/"*** directory. If the tool doesn't find a suitable candidate, it tries to look for it online in this repository and download it on your device.

# :scroll: Functions and their numbers
## Main functions
Although nearly all of the names are self-explanatory, I'm leaving a short note below each one of them.
### 0. Exit
Safely terminates the script.
### 1. Patch | Unpatch scripts
Tries to patch or reverse patch the scripts on Steam Deck if a compatible patch exists in the ***"./patches/"*** directory. Before doing so you would want to run **"2. Backup scripts"** option just in case you need it later. 

> [!IMPORTANT]
> Unpatch option works only when the scripts were previously patched by this tool.

### 2. Backup scripts
Makes a backup of script files and stores it in the ***"./backup/"*** directory.
### 3. Restore backupped scripts
Restores a backup selected from a ***"./backup/"*** directory.
## Hidden functions
You can make the program display these options in the main menu by setting the **"SHOW_HIDDEN_OPTIONS"** flag to **"1"** in the ***"settings.json"*** file.
### 97. Toggle steamos-readonly status
Allows you to change the steamos-readonly status to the opposite of the current one.
### 98. Prepare a workbench
Unpacks a previously made backup to the ***"./workbench/original/"*** directory and copies script files to the ***"./workbench/patched/"*** directory. Having all that set, you can try to make a change to the scripts inside the ***"./workbench/patched/"*** directory.

> [!NOTE]
> There are additional files in the ***"./workbench/org_intel/"*** directory that are not needed to create the patch, but may be helpful.

### 99. Create a patch file
After you change everything you want, you can run this option to compare files from both directories and get your own patch as a result. The file will be saved in the ***"./patches/"*** directory. 

> [!WARNING]
> You have to run it from a SteamOS on a Steam Deck as it will take the current SteamOS build as a patch version. Using other Linux distros won't work.

## Are we done?
After completion of each function, you will be asked if that's all for now. You can choose '**No**' to come back to the list of all functions.
# :mega: Additional notes
## Password and root privileges
A majority of options require root privileges. If you've already set your custom password, the script will ask you to type it. It will be stored as an encrypted variable for the time of running the script. Otherwise, the script will use the default password which is **"GabeNewell#1"**. Unless you're using your own password, it will be removed at the end of each option execution.
## Enabling password remembering
By default, remembering the user's custom password is disabled.
You can change it by setting the **"REMEMBER_PASSWORD"** flag to **"1"** in the ***"settings.json"*** file. After the change, the script will remember the next entered password and save it in the encrypted ***".user.sec"*** file.
## Adding your own patches
The tool uses the data from the ***"./patches/_patches.csv"*** file to identify the correct patch. Info about patches created with a workbench is added to the ***"./patches/_patches_own.csv"*** file. That file overrides data from the first mentioned file.
The structure of both files is as follows:
```markdown
e4765353a6fe36f254e67a3f7c62719e;b5ce0513-9d81-4c16-b7f9-c3b3fa2cee16;O
9d212ba6f4e7afce19d8eb3a836065af;b5ce0513-9d81-4c16-b7f9-c3b3fa2cee16;P
```
#### EXPLANATION:
md5 checksum of sha256 checksums of the script files separated by a "|" character;random GUID which is used as patch filename;letter "P" (Patched) or "O" (Original)

## BTRFS Mounting options
| Build             | Mounting options                                                            |
|-------------------|-----------------------------------------------------------------------------|
| **< 20221221.2**  | **compress-force=zstd:15**                                                  |
| **>= 20221221.2** | **compress-force=zstd:6**, **lazytime**, **space_cache=v2**, **ssd_spread** |
| **>= 20231116.2** | **compress-force=zstd:6**, **lazytime**, **space_cache=v2**                 |

## NTFS Mounting options
| Build               | Mounting options                                                            |
|---------------------|-----------------------------------------------------------------------------|
| **>= 20231116.2**   | **windows_names**, **lazytime**, **big_writes**                             |
| **>= 20240626.100** | **windows_names**, **lazytime**                             |

# :fire: Issues
All the problems I've encountered during my tests have been fixed on the go. If you find any other issue (hope you won't) then please, feel free to report it [there](https://github.com/mi5hmash/SteamDeckBTRFS/issues).
# :star: Credits
[Trevo525](https://github.com/Trevo525) - he did great research and his repository is a mine of information.

Sources:
* https://www.howtogeek.com/734838/how-to-use-encrypted-passwords-in-bash-scripts/
* https://www.howtogeek.com/415442/how-to-apply-a-patch-to-a-file-and-create-patches-in-linux/
