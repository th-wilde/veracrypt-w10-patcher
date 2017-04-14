# Windows 10 media patcher for upgrading VeraCrypt encrypted systems
This Script prepares a Windows 10 installation media to upgrade
VeraCrypt encrypted Windows 10 Systems without need to decrypting them.


## General
Hello security aware peoples,  
I found a way to Upgrade Windows 10 (Any Version up to the current 1703) without decrypting the System Drive. I tested it on 64Bit Windows with the “entire system drive” encryption in BIOS-Mode and “Windows Partition” encryption in UEFI-Mode. Maybe some of you may try other configurations.

Note that you can Upgrade any Windows 10 Version direct to the current 1703 without installing the intermediate Versions.
Below is described how it works. But it’s a bit complicated. I created a Script, that’s do the work.  Also, there is a Video-Tutorial about Script usage and the Upgrade.

Disclaimer: I don’t take any responsibility for whatever happens. Be prepared for the worst-case scenario! (Loss of data)

Script: [Link Follows]

Place it into the root of a Windows 10 installation media (you can create one via the [media creation tool](https://www.microsoft.com/en-us/software-download/windows10) form Microsoft) and run it with administrator rights. It will patch the VeraCrypt-Driver into it. After completion (this may take a while), run the setup.exe from the root of the installation media and follow the instructions on screen. 

The modified installation media can be used to upgrade multiple Machines. In this case, mind to upgrade the machine to the same VeraCrypt version that the installation media contains. Don’t mix Architectures (64Bit/32Bit) while patching. Use a 64Bit System to Patch a 64Bit installation media and vice versa. 

Video-Tutorial (Shows VeraCrypt in UEFI-Mode): [Link Follows]


## The Problem with the Upgrade
The upgrade process is more a reinstall than an update of the Windows 10 OS. This reinstall-mechanism do not work (out of the box) if the Drive/Partition is encrypted with VeraCrypt. I digged around and figured out how the reinstall is done.
1.	The Setup copy’s the new Win10 OS (parallel to the running one) on the System drive.
2.	The Setup generates a “SaveOS” (from the WinRE-Image of the new Win10 OS) that will swap the old Win10 against the new Win10. The setup restarts into this “SaveOS” by changing the Windows-Bootloader configuration (not the Bootloader itself).
3.	After OS swapping, the “SaveOS” starts the new Win10. This will do initialization like detecting Hardware, installing Drivers and transfer stuff (Driver, Settings, etc.) from the old OS.
4.	After initialization, the new Win10 OS restarts, do some late work and goes on to the Login-Screen or Desktop.
The Problem is Step 2 and 3. The “SaveOS” (Step 2) don’t contain the needed VeraCrypt driver to access the encrypted Partition/Drive. Also, the new Win10 OS on its first start (Step 3) misses the VeraCrypt driver. Booth will cause a rollback of the Upgrade. The System will be stuck at its outdated Version forever.


## What does the script?
Primary it utilizes Windows build-in DISM (Distribution Imaging Servicing and Management) tool (dism.exe) to inject the VeraCrypt-Driver into all Images (for each Edition of Windows one) inside the install.wim file. 

Some explanations how its done:

1.  If necessary convert the containing /sources/install.esd (recovery only image) to a /sources/install.wim (common windows image).
    1.  The install.esd contains usually 3 OS-Images. Win10 Pro, Win10 Core (aka Home), Win10 Education (variant of Enterprise that do not contain the MS-Bloatware). Containing Images can be shown by “dism /Get-WimInfo /wimFile:C:\Path\to\install.esd”.
    2.  Extract every displayed OS-Image in there index-order into one install.wim. This can be done by repeating this with ascending index-numbers  “dism /image-extract /souceImage: C:\Path\to\install.esd /souceIndex:[Index-Number] /destinationImage: C:\Path\to\install.wim”
    3.  Delete the install.esd-File. 
2.  Inject the Veracrypt-Driver into the OS-Images inside the install.wim
    1.  Mount a OS-Image into a Folder via “dism /mountWim /WimFile: C:\Path\to\install.wim /index:[index-number] /MountDir:C:\path\to\mount”
    2.  Injecting the Veracyrpt-Driver by copying it from the running OS (C:\Windows\System32\Drivers\veracrypt.sys) into the mounted OS-Image
    3.  Updating the Registry (HKLM\System Hive) of the OS-Image to load the VeraCrypt -Driver by temporarily adding the C:\path\to\mount\Windows\System32\config\SYSTEM Structure and importing necessary Keys.
    4.  Inject the VeraCrypt driver into the WinRE-Image located under \Windows\System32\Recovery\WinRe.wim inside the OS-Image. The process is the same like for the OS-Images (Steps i,ii,iii,v). Dism can mount different Images into different Folders at the same time.
    5.  Unmount the OS-Image via “dism /unmountwim /mountdir: C:\path\to\mount /commit”
3.  Run the setup.exe und follow the instructions on screen. The Upgrade should now work normally.


It’s either black magic or easy going. It is just an overview how it works. For Details check the Script.
Enjoy your up to date “Windows as a Service”.
