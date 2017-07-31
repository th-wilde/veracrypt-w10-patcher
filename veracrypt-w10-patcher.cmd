@echo off
rem Windows 10 media patcher for VeraCrypt
rem Created 14.04.2017 by Thorben Wilde


pushd %~dp0

echo.
echo =============================================================================
echo Windows 10 media patcher for upgrading VeraCrypt encrypted systems
echo.
echo This script prepares a Windows 10 installation media to upgrade
echo VeraCrypt encrypted Windows 10 Systems without need to decrypting them.
echo.
echo Some commands done by this script will display error messages.
echo This is normal behavior and will be handled by the Script.
echo =============================================================================
echo Windows 10 Medien Parcher zum Upgraden von VeraCrypt verschlsselten Systemen
echo.
echo Dieses Script bereitet ein Windows 10 Installationsmedium vor um
echo VeraCrypt verschlsselte Windows 10 Systeme upzugraden, ohne dass diese 
echo entschlsselt werden mssen.
echo.
echo Einige Befehle, die von diesem Script ausgefhrt werden, zeigen
echo Fehlermeldungen an. Das ist normales Verhalten und wird vom Script behandelt.
echo =============================================================================
echo.
pause
fsutil dirty query %systemdrive% >nul
if not "%errorlevel%" == "0" (
	echo.
	echo ===================================================================
	echo This script need administrator rights to work.
	echo Open the Context-Menu ^(usually  right klick^) for this Script
	echo and select "Run as Administrator"
	echo ===================================================================
	echo Dieses Script ben”tigt Administratorrechte um zu funktionieren.
	echo ™ffne das Kontextmen ^(blicherweise Rechtsklick^) fr dieses Script
	echo und w„hle "Als Administrator ausfhren"
	echo ===================================================================
	echo.
	pause
	goto :eof
) 

if not exist %SystemRoot%\System32\drivers\veracrypt.sys (
	echo.
	echo ========================================================================
	echo It seems that VeraCrypt is not installed on this Machine.
	echo ^(%SystemRoot%\System32\drivers\veracrypt.sys does not exist.^)
	echo This preparation must be done on a Machine where VeraCrypt is installed.
	echo ========================================================================
	echo Es scheint als w„hre VeraCrypt nicht auf dieser Maschine installiert.
	echo ^(%SystemRoot%\System32\drivers\veracrypt.sys existiert nicht.^)
	echo Diese Vorbereitung muss auf einer Maschine mit installiertem VeraCrypt
	echo durchgefhrt werden.
	echo ========================================================================
	echo.
	pause
	goto :eof
)

if exist sources\install.esd (
	call :convert
)

if exist sources\install.wim (

	call :patch

	echo.
	echo ======================================================================
	echo Preparation  done.
	echo Start the Windows 10 upgrade by executing setup.exe manually
	echo ======================================================================
	echo Vorbereitungen abgeschlossen.
	echo Starte das Windows 10 Upgrade durch manuelles ausfhren der setup.exe.
	echo ======================================================================
	echo.
) else (
	echo.
	echo ==========================================================================
	echo Error!
	echo install.wim/install.esd missing!
	echo Is this Script placed inside the right directory?
	echo It meant to be placed in the root of a Windows 10 installation media and 
	echo expects a "sources" directory that contains a install.wim or install.esd
	echo ==========================================================================
	echo Fehler!
	echo install.wim/install.esd fehlt!
	echo Ist dieses Script im richtigen Verzeichnis abgelegt?
	echo Es ist vorgesehen das es im Wurzelverzeichnis eines Windows 10 
	echo Installationsmediums abgelegt ist und erwartet einen "sources" Verzeichnis
	echo welches eine install.wim oder install.esd enth„lt.
	echo ==========================================================================
	echo.
)

pause

popd
goto :eof

:patch	

	echo.
	echo ===========================================
	echo Inject VeraCrypt into install.wim
	echo ===========================================
	echo Injizieren von VeraCrypt in die install.wim
	echo ===========================================
	echo.

	mkdir mounted-install-wim
	mkdir mounted-winre-wim

	set imageIndex=0
	:loopImagesPatch
	set /a imageIndex=imageIndex+1 >NUL
	DISM.exe /Mount-Wim /WimFile:sources\install.wim /index:%imageIndex% /MountDir:mounted-install-wim
	if not "%errorlevel%" == "0" goto loopImagesPatchEnd
	DISM.exe /Mount-Wim /WimFile:mounted-install-wim\Windows\System32\Recovery\winre.wim /index:1 /MountDir:mounted-winre-wim
	
	copy %SystemRoot%\System32\drivers\veracrypt.sys mounted-install-wim\Windows\System32\drivers\veracrypt.sys
	copy %SystemRoot%\System32\drivers\veracrypt.sys mounted-winre-wim\Windows\System32\drivers\veracrypt.sys

	Reg LOAD HKLM\mounted-install-wim mounted-install-wim\Windows\System32\config\SYSTEM
	Reg LOAD HKLM\mounted-winre-wim mounted-winre-wim\Windows\System32\config\SYSTEM

	Reg ADD HKLM\mounted-install-wim\ControlSet001\Services\veracrypt /f
	Reg ADD HKLM\mounted-install-wim\ControlSet001\Services\veracrypt /f /v Type /t REG_DWORD /d 1
	Reg ADD HKLM\mounted-install-wim\ControlSet001\Services\veracrypt /f /v Start /t REG_DWORD /d 0
	Reg ADD HKLM\mounted-install-wim\ControlSet001\Services\veracrypt /f /v ErrorControl /t REG_DWORD /d 2
	Reg ADD HKLM\mounted-install-wim\ControlSet001\Services\veracrypt /f /v ImagePath /t REG_EXPAND_SZ /d System32\drivers\veracrypt.sys
	Reg ADD HKLM\mounted-install-wim\ControlSet001\Services\veracrypt /f /v DisplayName /t REG_SZ /d veracrypt
	Reg ADD HKLM\mounted-install-wim\ControlSet001\Services\veracrypt /f /v WOW64 /t REG_DWORD /d 1
	Reg ADD HKLM\mounted-install-wim\ControlSet001\Services\veracrypt /f /v Group /t REG_SZ /d Filter
	Reg ADD HKLM\mounted-install-wim\ControlSet001\Services\veracrypt /f /v VeraCryptConfig /t REG_DWORD /d 2
	Reg ADD HKLM\mounted-install-wim\ControlSet001\Control\Class\{4d36e967-e325-11ce-bfc1-08002be10318} /f /v UpperFilters /t REG_MULTI_SZ /d veracrypt\0PartMgr

	Reg ADD HKLM\mounted-winre-wim\ControlSet001\Services\veracrypt /f
	Reg ADD HKLM\mounted-winre-wim\ControlSet001\Services\veracrypt /f /v Type /t REG_DWORD /d 1
	Reg ADD HKLM\mounted-winre-wim\ControlSet001\Services\veracrypt /f /v Start /t REG_DWORD /d 0
	Reg ADD HKLM\mounted-winre-wim\ControlSet001\Services\veracrypt /f /v ErrorControl /t REG_DWORD /d 2
	Reg ADD HKLM\mounted-winre-wim\ControlSet001\Services\veracrypt /f /v ImagePath /t REG_EXPAND_SZ /d System32\drivers\veracrypt.sys
	Reg ADD HKLM\mounted-winre-wim\ControlSet001\Services\veracrypt /f /v DisplayName /t REG_SZ /d veracrypt
	Reg ADD HKLM\mounted-winre-wim\ControlSet001\Services\veracrypt /f /v WOW64 /t REG_DWORD /d 1
	Reg ADD HKLM\mounted-winre-wim\ControlSet001\Services\veracrypt /f /v Group /t REG_SZ /d Filter
	Reg ADD HKLM\mounted-winre-wim\ControlSet001\Services\veracrypt /f /v VeraCryptConfig /t REG_DWORD /d 2
	Reg ADD HKLM\mounted-winre-wim\ControlSet001\Control\Class\{4d36e967-e325-11ce-bfc1-08002be10318} /f /v UpperFilters /t REG_MULTI_SZ /d veracrypt\0PartMgr
	
	Reg UNLOAD HKLM\mounted-install-wim
	Reg UNLOAD HKLM\mounted-winre-wim
	
	DISM.exe /Unmount-Wim /MountDir:mounted-winre-wim /commit
	DISM.exe /Unmount-Wim /MountDir:mounted-install-wim /commit
	goto loopImagesPatch
	:loopImagesPatchEnd
	
	rmdir mounted-install-wim
	rmdir mounted-winre-wim
	
	echo.
	echo ====================
	echo install.wim patched
	echo ====================
	echo install.wim gepatcht
	echo ====================
	echo.

goto :eof

:convert	

	echo.
	echo ==============================================
	echo Convert install.esd to install.wim
	echo ==============================================
	echo Umwandeln der install.esd zu einer install.wim
	echo ==============================================
	echo.

	set imageIndex=0
	:loopImagesConvert
	set /a imageIndex=imageIndex+1 >NUL
	DISM.exe /Export-Image /SourceImageFile:sources\install.esd /SourceIndex:%imageIndex% /DestinationImageFile:sources\install.wim /Compress:max /CheckIntegrity
	if not "%errorlevel%" == "0" goto loopImagesConvertEnd
	goto loopImagesConvert
	:loopImagesConvertEnd
	del sources\install.esd
	
	echo.
	echo ====================
	echo install.wim created
	echo ====================
	echo install.wim erstellt
	echo ====================
	echo.

goto :eof