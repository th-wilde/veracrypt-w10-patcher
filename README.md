# Windows 10 media patcher for upgrading VeraCrypt-encrypted systems
This script prepares a Windows 10 installation media to upgrade VeraCrypt-encrypted Windows 10 systems **without the need to decrypt them**.

## Update
* **It still works for the new "Windows 10 April Update" (Version 1803)!** Tested configuration: 1709 to 1803 upgrade of 64-bit Windows 10 Pro with the “entire system drive” encryption in BIOS mode.
* Unsure if the upgrade works for your specific configuration? Check the ["Hall of Fame"-Issue](https://github.com/th-wilde/veracrypt-w10-patcher/issues/2) for reports of successful upgrades and the ["Hall of Blame"-Issue](https://github.com/th-wilde/veracrypt-w10-patcher/issues/3) for unsuccessful upgrades.

## General
First: I’m not a native English speaker. Pardon me for spelling mistakes.

Hello, security-aware people,  
I found a way to upgrade Windows 10 (any version up to the current ~~1703~~ 1709) without decrypting the System Drive. I tested it on 64-bit Windows with the “entire system drive” encryption in BIOS mode and “Windows Partition” encryption in UEFI mode. Maybe some of you may try other configurations… it should also work for 32-bit installations.

Note that you can upgrade any Windows 10 version directly to the current version without installing the intermediate versions.
How it works is described below, but it’s a bit complicated. I created a script that does the work. Also, there is a video tutorial about script usage and the upgrade.

**Disclaimer: I don’t take any responsibility for whatever happens. Be prepared for the worst-case scenario! (Loss of data)**

Script: https://github.com/th-wilde/veracrypt-w10-patcher/archive/master.zip

Place the script into the root of a Windows 10 installation media (You can create one using the [media creation tool](https://www.microsoft.com/en-us/software-download/windows10) from Microsoft.) and run it with administrator rights. The script will patch the VeraCrypt driver into the installation media. After completion (This may take a while.), run the setup.exe from the root of the installation media and follow the instructions on screen. Don’t boot from the created media! This would end in a normal installation process instead of an upgrade.

>*Only on UEFI mode:*  
>The upgrade requires the Windows bootloader entry (which VeraCrypt has replaced/removed) in the UEFI firmware (NVRAM) to work properly. To add the entry, boot up a Windows 10 installation media and access the command line by pressing SHIFT + F10.  Run the following command:  
>`bcdedit /set {fwbootmgr} displayorder {bootmgr} /addlast`  
>Reboot back to the encrypted Windows OS and start the upgrade.  
>The bootloader entry is never used. Optionally it can be removed with following command from an elevated command line:  
>`bcdedit /set {fwbootmgr} displayorder {bootmgr} /remove`


The modified installation media can be used to upgrade multiple machines. In this case, be sure to upgrade the machine to the same VeraCrypt version that the installation media contains. Don’t mix architectures (64-bit/32-bit) while patching. Use a 64-bit system to patch 64-bit installation media and vice versa. 

**Video-Example/Tutorial:** https://youtu.be/uK-kUTNiWIk

The video shows VeraCrypt in UEFI mode on a VirtualBox VM performing an upgrade to the "Creators Update" (1703).

**Please feel free to report your (un)successful Upgrade in the ["Hall of Fame"-Issue](https://github.com/th-wilde/veracrypt-w10-patcher/issues/2) or ["Hall of Blame"-Issue](https://github.com/th-wilde/veracrypt-w10-patcher/issues/3) to help other users.**

## The problem with the upgrade
The upgrade process is more a reinstall than an update of the Windows 10 OS. This reinstallation mechanism does not work (out of the box) if the drive/partition is encrypted with VeraCrypt. I dug around and figured out how the reinstall is done.


1.	The Setup copies the new Win10 OS (parallel to the running one) on the System drive.
2.	The Setup generates a “SaveOS” (from the WinRE image of the new Win10 OS) that will swap the old Win10 against the new Win10. The setup restarts into this “SaveOS” by changing the Windows bootloader *configuration* (not the bootloader itself).
3.	After OS swapping, the “SaveOS” starts the new Win10. This will do initialization, such as detecting hardware, installing drivers and transferring stuff (driver, settings, etc.) from the old OS.
4.	After initialization, the new Win10 OS restarts, does some final work and goes on to the login screen or desktop.


The problem is Steps 2 and 3. The “SaveOS” (Step 2) doesn’t contain the needed VeraCrypt driver to access the encrypted partition/drive. Also, the new Win10 OS on its first start (Step 3) misses the VeraCrypt driver. Both will cause a rollback of the upgrade. The system will be stuck at its outdated version forever.


## What does the script do?
Primarily, it utilizes Windows's built-in DISM (Distribution Imaging Servicing and Management) tool (dism.exe) to inject the VeraCrypt driver into all the images (one for each edition of Windows) inside the install.wim file. 

Some explanations of how its done:

1.  If necessary, convert the containing /sources/install.esd (recovery only image) to a /sources/install.wim (common Windows image).
    1.  The install.esd usually contains multiple OS images. There is an image for each edition and variant of Windows 10. For the "Fall Creators Update" the "Media Creation Tool" media contains 8 images: 4 editions (Pro, Core [aka Home], Education, and the new "S" edition) times 2 variants (Normal, and the "N" variant [which comes without media playback support - i.e. without the Windows media player - for legal reasons]). All OS images must be present inside the install.wim or the setup will not allow an upgrade. Containing images can be shown by “dism /Get-WimInfo /wimFile:C:\Path\to\install.esd”.
    2.  Extract every displayed OS image in their index-order into one install.wim. This can be done by repeating this with ascending index-numbers  “dism /image-extract /souceImage: C:\Path\to\install.esd /souceIndex:[Index-Number] /destinationImage: C:\Path\to\install.wim”
    3.  Delete the install.esd file. 
2.  Inject the VeraCrypt driver into the OS images inside the install.wim
    1.  Mount a OS image into a folder via “dism /mountWim /WimFile: C:\Path\to\install.wim /index:[index-number] /MountDir:C:\path\to\mount”
    2.  Inject the VeraCyrpt driver by copying it from the running OS (C:\Windows\System32\Drivers\veracrypt.sys) into the mounted OS image
    3.  Update the registry (HKLM\System Hive) of the OS image to load the VeraCrypt driver by temporarily adding the C:\path\to\mount\Windows\System32\config\SYSTEM structure and importing necessary keys.
    4.  Inject the VeraCrypt driver into the WinRE image located under \Windows\System32\Recovery\WinRe.wim inside the OS image. The process is the same as for the OS images (Steps i,ii,iii,v). DISM can mount different images into different folders at the same time.
    5.  Unmount the OS image via “dism /unmountwim /mountdir: C:\path\to\mount /commit”
3.  Run the setup.exe and follow the instructions on screen. The upgrade should now work normally.


It’s either black magic or easy going. This is just an overview of how it works. For details, check the script.
Enjoy your up-to-date “Windows as a Service”.
