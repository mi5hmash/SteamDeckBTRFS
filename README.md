[![License: MIT](https://img.shields.io/badge/License-MIT-blueviolet.svg)](https://opensource.org/licenses/MIT)
[![Release Version](https://img.shields.io/github/v/tag/mi5hmash/SteamDeckBTRFS?label=version)](https://github.com/mi5hmash/SteamDeckBTRFS/releases/latest)
![Latest Known Supported SteamOS](https://img.shields.io/badge/Latest%20Suppored%20SteamOS-3.3%20--%20build%2020220803.1-success)
[![Visual Studio Code](https://img.shields.io/badge/--007ACC?logo=visual%20studio%20code&logoColor=ffffff)](https://code.visualstudio.com/)

# :interrobang: SteamDeckBTRFS - What is it?
<img src="https://github.com/mi5hmash/SteamDeckBTRFS/blob/main/.resources/images/cover.png" alt="cover" width="460"/>

It's a shell script for lazy people like me who want to use [BTRFS](https://btrfs.wiki.kernel.org/index.php/Main_Page) formatted microSD cards on their decks, but don't want to type many commands into a command line. Worry no more as I got you covered.

**Despite that it's simple, you're still <mark>using it at your own risk</mark>. I've tried my best to make it foolproof and I always run tests before release until I consider it stable, but some things may show up only after a long time of use. You've been warned.**
# :tipping_hand_person: Yet another repository? | How is it different?
There are other repositories like mine. They are based on replacing entire scripts with the ones that have been already patched. My approach is to **patch the original scripts directly** using a small patch file. My tool also lets you **perform a reverse patch (unpatch)** operation on the patched scripts or **create a backup** of original scripts so it can be used later to **restore original files**.
# :performing_arts: Pros and cons
Everything has been well explained in the 
[btrfdeck repository](https://github.com/Trevo525/btrfdeck) by [Trevo525](https://github.com/Trevo525). Instead of copy-pasting everything from there here and thus committing plagiarism, I will just encourage you to go there and read the original content of that repo.
# :runner: Running the script
Grab the [latest release](https://github.com/mi5hmash/SteamDeckBTRFS/releases/latest) and unpack it on your Steam Deck.
Then right-click on the ***'SteamDeckBTRFS.sh'*** and select "Run in Konsole". 

<img src="https://github.com/mi5hmash/SteamDeckBTRFS/blob/main/.resources/images/run.png" alt="run" width="415"/>

**Do not attempt to execute it by clicking twice on it, because this will run the script in a hidden window.**

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

> **Note:** Unpatch option works only when the scripts was previously patched by this tool.

### 2. Backup scripts
Makes a backup of script files and stores it in the ***"./backup/"*** directory.
### 3. Restore backupped scripts
Restores a backup, chosen from a ***"./backup/"*** directory.
## Hidden functions
### 97. Toggle steamos-readonly status
Allows you to change the steamos-readonly status to the opposite of the current one.
### 98. Prepare a workbench
Unpacks a previously made backup to ***"./workbench/original/"*** directory and copies script files to ***"./workbench/patched/"*** directory. Having all that set, you can try to make a change to the scripts inside the ***"./workbench/patched/"*** directory.

> **Note:** There are additional files in the ***"./workbench/org_intel/"*** directory that are not needed to create the patch, but may be helpful.

### 99. Create a patch file
After you change everything you want, you can run this option to compare files from both directories and get your own patch in result. The file will be saved in the ***"./patches/"*** directory. 

> **Note:** You have to run it from a SteamOS on a Steam Deck as it will take the current SteamOS build as a patch version. Using other Linux distros won't work.

## Are we done?
After completion of each function, you will be asked if that's all for now. You can choose '**No**' to come back to the list of all functions.
# :mega: Additional notes
## Password and root privileges
A majority of options require root privileges. If you've already set your custom password, the script will ask you to type it. It will be stored as an encrypted variable for the time of running the script. Otherwise, the script will use the default password which is **"GabeNewell#1"**. Unless you're using your own password, it will be removed at the end of each option execution.
## Adding own patches
The tool uses the data from the ***"./patches/_patches.csv"*** file to identify the correct patch. Info about patches created with a workbench is added to the ***"./patches/_patches_own.csv"*** file. That file overrides data from the first mentioned file.
The structure of both files is as follows:

<span style="color:blue">e4765353a6fe36f254e67a3f7c62719e</span>;<span style="color:green">b5ce0513-9d81-4c16-b7f9-c3b3fa2cee16</span>;<span style="color:red">O</span>
<span style="color:blue">9d212ba6f4e7afce19d8eb3a836065af</span>;<span style="color:green">b5ce0513-9d81-4c16-b7f9-c3b3fa2cee16</span>;<span style="color:red">P</span>

##### EXPLANATION:
<span style="color:blue">md5 checksum of sha256 checksums of the script files separated by a "|" character</span>;<span style="color:green">random GUID which is used as patch filename</span>;<span style="color:red">letter "P" (Patched) or "O" (Original)</span>

# :fire: Issues
All the problems I've encountered during my tests have been fixed on the go. If you find any other issue (hope you won't) then please, feel free to report it [there](https://github.com/mi5hmash/SteamDeckBTRFS/issues).
# :star: Credits
[Trevo525](https://github.com/Trevo525) - he did great research and his repository is the mine of information.

Sources:
* https://www.howtogeek.com/734838/how-to-use-encrypted-passwords-in-bash-scripts/
* https://www.howtogeek.com/415442/how-to-apply-a-patch-to-a-file-and-create-patches-in-linux/