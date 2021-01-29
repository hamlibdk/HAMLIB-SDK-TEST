# -----------------------------------------------------------------------------
# Name ..............: jtbuild.ps1
# Description .......: Test Build script for WSJT-X, JTDX and JS8CALL
# Concept ...........: Greg, Beam, KI7MT, <ki7mt@yahoo.com>
# Author ............: JTSDK Contributors 20-01-2021 ->
# Copyright .........: Copyright (C) 2018-2021 Greg Beam, KI7MT
#                      Copyright (C) 2018-2021 JTSDK Contributors ->
# License ...........: GPL-3
#
# jtbuild.cmd adjustments: Steve VK3VM to work with JTSDK 3.1 12-04 --> 11-12-2020
#
# # Code is capable of auto-downloading from a WSJTX, JTDX or JS8CALL repository
# based on flag [ src-wsjtx | src-jtdx | src-js8call ] in C:\JTSDK64-Tools\config
# 
# Stage 1 objectives (PowerShell conversion; refactoring; prime functionality; 
# Qt-independence) commenced 20-1-2020. Objectives met 29-01-2021 (Steve VK3VM)
#
# jtbuild-test.ps1 is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation either version 3 of the License, or (at your option) any
# later version. 
#
# This script is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#-----------------------------------------------------------------------------#

# ---------------------------------------------------------------- THIS IS THE END !!!
function TheEnd($code) {

	Push-Location $env:JTSDK_HOME\tools\msys64\usr\bin
	Rename-Item $env:JTSDK_HOME\tools\msys64\usr\bin\sh-bak.exe $env:JTSDK_HOME\tools\msys64\usr\bin\sh.exe | Out-Null
	Pop-Location

	exit($code)
}

# ---------------------------------------------------------------- COMMENCE BUILD
function CommenceBuild {
	Param ($srcOrigin)
	
	Write-Host ""
	Write-Host "--------------------------------------------"
	Write-Host " Commencing Build of $srcOrigin"
	Write-Host "--------------------------------------------"
	Write-Host ""
}

# ---------------------------------------------------------------- PROCESS OPTIONS
function ProcessOptions {
	Param ($aarg, [ref]$rcopt, [ref]$rtopt)

	if ($aarg -eq "Zero") { HelpOptions } 
	if ($aarg -eq "-h") { HelpOptions } 
	if ($aarg -eq "help") { HelpOptions }
	if ($aarg -eq $null) { HelpOptions } 	

	# if ($args[0] -eq "-o") { OptionStatus }

	#Case Independence of arguments conversion
	#very grotty error overcome error method
	#try {
		if (!($aarg -like "*System.Management*")) {
			if ($aarg -ne $null) { $aarg=($aarg).ToLower() }
	}
	#catch { }

	if ($aarg -like "rconfig") { 
		$rcopt.Value="Release"
		$rtopt.Value="Config"
	}

	if ($aarg -like "dconfig") { 
		$rcopt.Value="Debug"
		$rtopt.Value="Config"
	}

	if ($aarg -like "rinstall") { 
		$rcopt.Value="Release"
		$rtopt.Value="Install"
	}

	if ($aarg -like "dinstall") { 
		$rcopt.Value="Debug"
		$rtopt.Value="Install"
	}

	if ($aarg -like "package") { 
		$rcopt.Value="Release"
		$rtopt.Value="Package"
	}

	if ($aarg -like "docs") { 
		$rcopt.Value="Release"
		$rtopt.Value="Docs"
	}

	if (($rcopt.Value -eq $null) -or ($rtopt.Value -eq $null)) { HelpOptions }
}

# ---------------------------------------------------------------- DOWNLOAD SOURCE
# If no switch in env:JTSDK_CONFIG src-wsjtx is set for you !
# setting src-null in env:JTSDK_HOME\tmp forces a pull-down !
function DownloadSource {
	Param($srcd)
	if (!(Test-Path $srcd)) { 
		# Write-Host ""
		Write-Host "* No source directory detected."
		Write-Host ""
		Remove-Item "$env:JTSDK_HOME\tmp\*" -include src-* | Out-Null
		Out-File -FilePath "$env:JTSDK_HOME\tmp\src-null" | Out-Null
	}

	# Source selection changed detection block 
	if ((Test-Path $env:JTSDK_CONFIG\src-wsjtx)) { 
		if (!(Test-Path $env:JTSDK_HOME\tmp\src-wsjtx)) { 
			SelectionChanged("src-wsjtx") 
		} 
	} else { 
		if ((Test-Path $env:JTSDK_CONFIG\src-jtdx))  { 
			if (!(Test-Path $env:JTSDK_HOME\tmp\src-jtdx)) { 
				SelectionChanged("src-jtdx") 
			}			
		} else {
			if ((Test-Path $env:JTSDK_CONFIG\src-js8call))  { 
				if (!(Test-Path $env:JTSDK_HOME\tmp\src-js8call)) { 
					SelectionChanged("src-js8call") 
				} 
			}
		}
	}
}

# ---------------------------------------------------------------- GENERATE ERROR
function GenerateError($type) {
	Write-Host "*** Error: $type ***"
	Write-Host "*** Report error to JTSDK@Groups.io *** "
	Write-Host ""
	TheEnd(-1)
}

# ---------------------------------------------------------------- CLONE SOURCE FUNCTIONS
function CloneWSJTX {
	Write-Host ""
	Write-Host "* Downloading WSJTX from Home Repository"
	Write-Host ""
	Set-Location $env:JTSDK_TMP
	$url = "git://git.code.sf.net/p/wsjt/wsjtx"
	Write-Host "URL...: $url"
	git clone $url $srcd
	Remove-Item "$env:JTSDK_TMP\src*" | Out-Null
	Write-Host ""
	Write-Host "* WSJTX set as Previous" 
	Out-File -FilePath "$env:JTSDK_HOME\tmp\src-wsjtx" | Out-Null
}

function CloneJTDX {
	Write-Host ""
	Write-Host "* Downloading JTDX from Home Repository"
	Write-Host ""
	Set-Location $env:JTSDK_TMP
	$url = "https://github.com/jtdx-project/jtdx.git"
	Write-Host "URL...: $url"
	git clone $url $srcd
	Remove-Item "$env:JTSDK_TMP\src*" | Out-Null
	Write-Host ""
	Write-Host "* JTDX set as Previous" 
	Out-File -FilePath "$env:JTSDK_HOME\tmp\src-jtdx" | Out-Null
}

function CloneJS8CALL {
	Write-Host ""
	Write-Host "* Downloading JS8CALL from Home Repository"
	Write-Host ""
	Set-Location $env:JTSDK_TMP
	$url = "https://widefido@bitbucket.org/widefido/js8call.git"
	Write-Host "URL...: $url"
	git clone $url $srcd
	Remove-Item "$env:JTSDK_TMP\src*"
	Write-Host ""
	Write-Host "* JS8CALL set as Previous" 
	Out-File -FilePath "$env:JTSDK_HOME\tmp\src-js8call" | Out-Null
}

# ---------------------------------------------------------------- SOURCE SELECTION CHANGED
function SelectionChanged($selection) {
	# Source selection has changed so delete old source
	if ((Test-Path $env:JTSDK_HOME\tmp\wsjtx)) {
		# Write-Host ""
		Write-Host -NoNewline "* Deleting Original Source: " 
		Remove-Item $env:JTSDK_HOME\tmp\wsjtx -Recurse -Force | Out-Null
		Write-Host "Done"
	} else {
		Write-Host "  --> Setting configuration marker for wsjtx"
		Out-File -FilePath "$env:JTSDK_CONFIG\src-wsjtx"
	}

	if ($selection -eq "src-wsjtx") { CloneWSJTX }
	if ($selection -eq "src-jtdx") { CloneJTDX }
	if ($selection -eq "src-js8call") { CloneJS8CALL }	
}

# ---------------------------------------------------------------- NO SOURCE
function NoSource {
	Write-Host ""
	Write-Host "--------------------------------------------"
	Write-Host " NO SOURCE CODE"
	Write-Host "--------------------------------------------"
	Write-Host ""
	Write-Host " Place ONE of the following marker files in:" 
	Write-Host " $env:JTSDK_CONFIG"
	Write-Host ""
	Write-Host "` - src-wsjtx ... Pull git package for WSJT-X "   
	Write-Host "` - src-jtdx .... Pull git package for JTDX"
	Write-Host "` - src-js8call . Pull git package for JS8CALL"
	Write-Host ""
	TheEnd(-1)
}

# ---------------------------------------------------------------- CMAKE ERROR
function ErrorCMake {
	Write-Host ""
	Write-Host "--------------------------------------------"
	Write-Host " CMAKE BUILD ERROR"
	Write-Host "--------------------------------------------"
	Write-Host ""
	Write-Host " There was a problem building `( $desc `)"
	Write-Host ""
	Write-Host " Check the screen for error messages."
	Write-Host ""
	Write-Host " Correct the issue then try to re-build."
	Write-Host ""
	Write-Host ""
	TheEnd(-1)
}

# ---------------------------------------------------------------- HELP OPTIONS
function HelpOptions {
	Write-Host ""
	Write-Host "--------------------------------------------"
	Write-Host " Default Build Commands"
	Write-Host "--------------------------------------------"
	Write-Host ""
	Write-Host " Usage .....`: jtbuild `[ OPTION `]"
	Write-Host " Example....`: jtbuild rinstall"
	Write-Host ""
	Write-Host " Options:"
	Write-Host ""
	Write-Host "    rconfig    Release, Config Only"
	Write-Host "    dconfig    Debug, Config Only"
	Write-Host "    rinstall   Release, Non-packaged Install"
	Write-Host "    dinstall   Debug, Non-packaged Install"
	Write-Host "    package    Release, Windows Package"
	Write-Host "    docs       Release, User Guide"
	Write-Host ""
	Write-Host " * To Display this message, type .....`: jtbuild `-h"
	Write-Host ""
	TheEnd(0)
}

# ---------------------------------------------------------------- BUILD INFORMATION
function BuildInformation {
	Write-Host "--------------------------------------------"
	Write-Host " Build Information"
	Write-Host "--------------------------------------------"
	Write-Host ""
	Write-Host "  Description ...`: $desc"
	Write-Host "  Version .......`: $aver"
	Write-Host "  Type ..........`: $copt"
	Write-Host "  Target ........`: $topt"
	Write-Host "  Tool Chain ....`: $qtv"
	Write-Host "  SRC ...........`: $srcd"
	Write-Host "  Build .........`: $buildd"
	Write-Host "  Install .......`: $installd"
	Write-Host "  Package .......`: $pkgd"
	Write-Host "  TC File .......`: $tchain"
	Write-Host "  Clean .........`: $cleanFirst"
	Write-Host "  Reconfigure ...`: $reconfigure"
	# Write-Host ""
}

# --------------------------------------------------------------- CONFIGURATION ONLY
function ConfigOnly {

	Set-Location -Path $buildd
	Write-Host ""
	Write-Host "--------------------------------------------"
	Write-Host " Configuring Build Tree"
	Write-Host "--------------------------------------------"
	Write-Host ""
	cmake -G "MinGW Makefiles" -Wno-dev -D CMAKE_TOOLCHAIN_FILE=$tchain `
		-D CMAKE_COLOR_MAKEFILE=OFF `
		-D CMAKE_BUILD_TYPE=$copt `
		-D CMAKE_INSTALL_PREFIX=$installd $srcd
	if ($LastExitCode -eq 1) { ErrorCMake }
	TheEnd(0)
}

# ---------------------------------------------------------------- FINISH CONFIGURATION
function FinishConfig {
	Write-Host ""
	Write-Host "--------------------------------------------"
	Write-Host " Configure Summary"
	Write-Host "--------------------------------------------"
	Write-Host ""
	Write-Host "   Description .`: $desc"
	Write-Host "   Version .....`: $aver"
	Write-Host "   Type ........`: $copt"
	Write-Host "   Target ......`: $topt"
	Write-Host "   Tool Chain ..`: $qtv"
	Write-Host "   Clean .......`: $cleanFirst"
	Write-Host "   Reconfigure .`: $reconfigure"
	Write-Host "   SRC .........`: $srcd"
	Write-Host "   Build .......`: $buildd"
	Write-Host "   Install .....`: $installd"
	Write-Host ""
	Write-Host " Config Only builds simply configure the build tree with"
	Write-Host " default options. To further configure or re-configure this build,"
	Write-Host " run the following commands:"
	Write-Host ""
	Write-Host "  cd $buildd"
	Write-Host "  cmake-gui ."
	Write-Host ""
	Write-Host " Once the CMake-GUI opens, click on Generate, then Configure"
	Write-Host ""
	Write-Host " You now have have a fully configured build tree."
	Write-Host ""
}

# ---------------------------------------------------------------- FINISHED UG MSG
function FinishUserGuide {
	$dn = Split-Path $docname -leaf
	Write-Host ""
	Write-Host "--------------------------------------------"
	Write-Host " User Guide Summary"
	Write-Host "--------------------------------------------"
	Write-Host ""
	Write-Host "   Name ........`: $dn"
	Write-Host "   Version .....`: $aver"
	Write-Host "   Type ........`: $copt"
	Write-Host "   Target ......`: $topt"
	Write-Host "   Tool Chain ..`: $qtv"
	Write-Host "   SRC .........`: $srcd"
	Write-Host "   Build .......`: $buildd"
	Write-Host "   Location ....`: $buildd\doc\$dn"
	Write-Host ""
	Write-Host " The user guide does *not* get installed like normal install"
	Write-Host " builds, it remains in the build folder to aid in browser"
	Write-Host " shortcuts for quicker refresh during development iterations."
	Write-Host ""
	Write-Host " The name `[ $dn `] also remains constant rather"
	Write-Host " than including the version infomation."
	Write-Host ""
	TheEnd(0)
}

# ---------------------------------------------------------------- FINISH PACKAGE MSG
function FinishPackage {
	Write-Host ""
	Write-Host "--------------------------------------------"
	Write-Host " Windows Installer Summary"
	Write-Host "--------------------------------------------"
	Write-Host ""
	Write-Host "   Name ........`: $wsjtxpkg"
	Write-Host "   Version .....`: $aver"
	Write-Host "   Type ........`: $copt"
	Write-Host "   Target ......`: $topt"
	Write-Host "   Tool Chain ..`: $qtv"
	Write-Host "   Clean .......`: $cleanFirst"
	Write-Host "   Reconfigure .`: $reconfigure"
	Write-Host "   SRC .........`: $srcd"
	Write-Host "   Build .......`: $buildd"
	Write-Host "   Location ....`: $pkgd\$wsjtxpkg"
	Write-Host ""
	Write-Host " To Install the package, browse to Location and"
	Write-Host " run as you normally do to install Windows applications."
	Write-Host ""
	TheEnd(0)
}

# ---------------------------------------------------------------- NSIS ERROR
function NSISError {
	Write-Host ""
	Write-Host "--------------------------------------------"
	Write-Host " WINDOWS INSTALLER BUILD ERROR"
	Write-Host "--------------------------------------------"
	Write-Host ""
	Write-Host " There was a problem building the package,"
	Write-Host " or the script could not find:"
	Write-Host ""
	Write-Host " $buildd\$WSJTXPKG"
	Write-Host ""
	Write-Host " Check the Cmake logs for any errors, or" 
	Write-Host " correct any build script issues that were" 
	Write-Host " obverved and try to rebuild the package."
	Write-Host ""
	TheEnd(-1)
}

# ---------------------------------------------------------------- PACKAGE TARGET FUNCTIONS
function PackageTarget {
	Set-Location -Path $buildd
	Write-Host ""
	Write-Host "--------------------------------------------"
	Write-Host " Building $env:JT_SRC "
	Write-Host "--------------------------------------------"
	Write-Host ""
	Write-Host "* Build Directory: $buildd"
	Write-Host ""
	
	# The following 2 lines first introduced by Steve VK3VM 30-4-2020 
	# removes an ald annoyance in final info screens !
	
	Write-Host "* Removing Old Install Packages `(if exist`)"
	Write-Host ""
	Get-childitem $buildd\* -include *.exe -recurse -force | Remove-Item
	
	# Remove-Item * -force -include *.exe | Out-Null

	Write-Host "--------------------------------------------"
	Write-Host ""
	
	if (!(Test-Path "$buildd\Makefile")) { PackageTargetOne }
	
	if ($reconfigure -eq "Yes") {
		PackageTargetOne
	} else {
		PackageTargetTwo
	}
}

function PackageTargetOne {
	cmake -G "MinGW Makefiles" -Wno-dev -D CMAKE_TOOLCHAIN_FILE=$tchain `
		-D CMAKE_BUILD_TYPE=$copt `
		-D CMAKE_INSTALL_PREFIX=$pkgd $srcd
	if ($LastExitCode -ne 0) { ErrorCMake }
	PackageTargetTwo
}

function PackageTargetTwo {
	$topt=($topt).ToLower()
	if ($cleanFirst -eq "Yes") { mingw32-make -f Makefile clean | Out-Null }
	Write-Host ""
	cmake --build . --target $topt -- -j $JJ
	if ($LastExitCode -ne 0) { NSISError }
	#	DIR /B $buildd\*-win64.exe >p.k & $/P wsjtxpkg=<p.k & rm p.k **** Equivalent Below ***
	$wsjtxpkg = Get-ChildItem -Path $buildd -Filter *-win64.exe | Select -First 1
	Write-Host "Copying package to`: $pkgd"
	Copy-Item -Path $buildd\$wsjtxpkg  -Destination $pkgd | Out-Null
	FinishPackage
}

# ---------------------------------------------------------------- SETUP DIRECTORIES
function SetupDirectories {
	
	Write-Host ""
	Write-Host "--------------------------------------------"
	Write-Host " Folder Locations"
	Write-Host "--------------------------------------------"
	Write-Host ""
	if (!(Test-Path "$buildd")) {  New-Item -Path "$buildd" -ItemType directory | Out-Null }
	if (!(Test-Path "$installd")) { New-Item -Path "$installd" -ItemType directory | Out-Null }
	if (!(Test-Path "$pkgd")) { New-Item -Path "$pkgd" -ItemType directory | Out-Null }
	Write-Host " Build .......`: $buildd"
	Write-Host " Install .....`: $installd"
	Write-Host " Package .....`: $pkgd"
	Write-Host ""
}

# ---------------------------------------------------------------- FINISH INSTALLATION
function FinishInstall {
	Write-Host ""
	Write-Host "--------------------------------------------"
	Write-Host " Build Summary"
	Write-Host "--------------------------------------------"
	Write-Host ""
	Write-Host "  Source ........`: $env:JT_SRC"
	Write-Host "  Description ...`: $desc"
	Write-Host "  Version .......`: $aver"
	Write-Host "  Type ..........`: $copt"
	Write-Host "  Target ........`: $topt"
	Write-Host "  Tool Chain ....`: $qtv"
	Write-Host "  Clean .........`: $cleanFirst"
	Write-Host "  Reconfigure ...`: $reconfigure"
	Write-Host "  SRC ...........`: $srcd"
	Write-Host "  Build .........`: $buildd"
	Write-Host "  Install .......`: $installd"
	
	# AUTO RUN ----------------------------------------------------------- 

	if ($autorun -eq "Yes") {
		Write-Host "  JTSDK Option ..: Autorun Enabled"
		Write-Host "  Starting ......: wsjtx $aver r$sver $desc in $copt mode"
		Write-Host ""
		if ($copt -eq "Debug") {
			Write-Host ""
			Set-Location -Path "$installd\bin"
			Invoke-Expression "cmd.exe /c ./wsjtx.cmd"
			TheEnd(0)
		} else {
			Write-Host ""
			Invoke-Expression "./wsjtx.exe" 
			TheEnd(0)
		}
		TheEnd(0)	
	} else {
		Write-Host ""
		TheEnd(0)
	}
}

# ---------------------------------------------------------------- INSTALL-TARGET
function InstallTarget {
	Set-Location -Path $buildd
	Write-Host ""
	Write-Host "--------------------------------------------"
	Write-Host " Building $env:JT_SRC Install Target"
	Write-Host "--------------------------------------------"
	Write-Host ""
	if (!(Test-Path "$buildd\Makefile")) { InstallTargetOne }
	if ($reconfigure -eq "Yes") { InstallTargetOne }
	InstallTargetTwo
}

function InstallTargetOne {
	# Write-Host "* In InstallTargetOne"
	cmake -G "MinGW Makefiles" -Wno-dev -D CMAKE_TOOLCHAIN_FILE=$tchain `
		-D CMAKE_BUILD_TYPE=$copt `
		-D CMAKE_COLOR_MAKEFILE=OFF `
		-D CMAKE_INSTALL_PREFIX=$installd $srcd
	if ($LastExitCode -ne 0) { ErrorCMake }
	InstallTargetTwo
}

function InstallTargetTwo {
	# Write-Host "* In InstallTargetTwo"
	$topt=($topt).ToLower()
	if ($cleanFirst -eq "Yes") { mingw32-make -f Makefile clean | Out-Null }
	cmake --build . --target $topt -- -j $JJ
	if ($LastExitCode -ne 0) { ErrorCMake }
	if ($copt -eq "Debug") { InstallTargetThree }
	FinishInstall
}

# DEBUG MAKE BATCH FILE ------------------------------------------ DEBUG BATCH FILE
function InstallTargetThree {
	# Write-Host "* In InstallTargetThree"
	Write-Host -NoNewLine "* Generating Debug Batch File ... "
	Set-Location -Path "$installd\bin"
	$of="wsjtx.cmd"
	if ((Test-Path $of)) { 	Remove-Item -Path $of -Force  }

	New-Item -Force $of > $null

	Add-Content $of "@ECHO OFF"
	Add-Content $of "REM -- Debug Batch File"
	Add-Content $of "REM -- Part of the JTSDK v2.0 Project"
	Add-Content $of "SETLOCAL"
	Add-Content $of "TITLE WSJT-X Debug Terminal"
	Add-Content $of "$PATH=.;.\data;.\doc;$fft;$gccd;$qt5d;$qt5a;$qt5p;$hl3"
	Add-Content $of "CALL wsjtx.exe"
	Add-Content $of "CD /D $dest"
	Add-Content $of "ENDLOCAL"
	Add-Content $of "COLOR 0B"
	Add-Content $of "EXIT /B 0"
	
	Write-Host "Complete"
	
	FinishInstall
}

# ---------------------------------------------------------------- USER GUIDE
function DocsTarget {
	Set-Location -Path $buildd
	Write-Host ""
	Write-Host "--------------------------------------------"
	Write-Host " Building $env:JT_SRC User Guide"
	Write-Host "--------------------------------------------"
	Write-Host ""
	if (!(Test-Path "$buildd\Makefile")) { DocsTargetOne }
	if ($reconfigure -eq "Yes") { DocsTargetOne }
	DocsTargetTwo
}

function DocsTargetOne {
	# Write-Host "* In DocsTargetOne"
	cmake -G "MinGW Makefiles" -Wno-dev -D CMAKE_TOOLCHAIN_FILE=$tchain `
		-D CMAKE_BUILD_TYPE=$copt `
		-D CMAKE_INSTALL_PREFIX=$installd $srcd
	if ($LastExitCode -ne 0) { ErrorCMake }
	DocsTargetTwo
}

function DocsTargetTwo {
	# Write-Host "* In DocsTargetTwo"
	if ($cleanFirst -eq "Yes") { mingw32-make -f Makefile clean | Out-Null }
	cmake --build . --target docs
	if ($LastExitCode -ne 0) { ErrorCMake }
	if ($copt -eq "Debug") { InstallTargetThree }
	# DIR /B $buildd\doc\*.html >d.n & $/P docname=<d.n & rm d.n
	$docname = Get-ChildItem -Path "$buildd\doc\*.html" -Filter *.html | Select -First 1

	FinishUserGuide
}

# ---------------------------------------------------------------- GET VERSION DATA
# Source is either from CMakeLists.txt or from Versions.cmake
function GetVersionData ([ref]$rmav, [ref]$rmiv, [ref]$rpav, [ref]$rrcx, [ref]$rrelx) {
	Write-Host "* Obtaining Source Version Data"
	Write-Host ""
	if (!(Test-Path "$env:JTSDK_TMP\wsjtx\Versions.cmake")) {
		$mlConfig = Get-Content $env:JTSDK_TMP\wsjtx\CMakeLists.txt
		Write-Host "  --> Retrieving from $env:JTSDK_TMP\wsjtx\CMakeLists.txt"
		[Int]$count = 0
		foreach ($line in $mlConfig) {
			if (($line.trim() |  Select-String -Pattern "\d{1,3}(\.\d{1,3}){3}" -AllMatches).Matches.Value) {
				$temp = ($line  |  Select-String -Pattern "\d{1,3}(\.\d{1,3}){3}" -AllMatches).Matches.Value
				Write-Host -NoNewLine "  --> Version data: $temp "
				$verArr = @($temp.split('.'))
				$rmav.value = $verArr[0]
				$rmiv.value = $verArr[1]
				$rpav.value = $verArr[2]
				$rrelx.value = $verArr[3]
			}
			if ($line -like 'set_build_type*') {
				$rrcx.value = ($line) -replace "[^0-9]" , ''
				Write-Host "rc $rcx"
				$count++
			}
		}

		if ($count -eq 0) { Write-Host "" }

		try { 
			if ($verArr[0] -eq 0) { GenerateError("Data not read from CMakeLists.txt" ) } 
		}
		catch { 
			GenerateError("Unable to read data from CMakeLists.txt") 
		}
	} else {	# From Versions.cmake -----------------
		$vcConfig = Get-Content $env:JTSDK_TMP\wsjtx\Versions.cmake
		Write-Host "  --> Retrieving from $env:JTSDK_TMP\wsjtx\Versions.cmake"
		[Int]$count = 0
		foreach ($line in $vcConfig) {
			if ($line -like '*WSJTX_VERSION_MAJOR*') {
				$rmav.value = ($line) -replace "[^0-9]" , ''
			}
			if ($line -like '*WSJTX_VERSION_MINOR*') {
				$rmiv.value = ($line) -replace "[^0-9]" , ''
			}
			if ($line -like '*WSJTX_VERSION_PATCH*') {
				$rpav.value = ($line) -replace "[^0-9]" , ''
			}
			if ($line -like '*WSJTX_RC*') {
				$rrelx.value = ($line) -replace "[^0-9]" , ''
			}
			if ($line -like '*WSJTX_VERSION_IS_RELEASE*') {
				$rrcx.value = ($line) -replace "[^0-9]" , ''
			}

			$count++
		}
		
		if ($count -ne 0) { 
			Write-Host "  --> Version data: $mav.$miv.$pav RC: $relx Release: $rcx "
		} else {
			GenerateError("Unable to read data from CMakeList.txt")
		}
	}
}

####################################################################
############################ MAIN LOGIC ############################
####################################################################

# Used to prevent CMake errors with MinGW Makefiles
# This prevents a long-standing annoyance seen while developing...  !!!
if (Test-Path("$env:JTSDK_HOME\tools\msys64\usr\bin\sh-bak.exe")) { 
	Rename-Item $env:JTSDK_HOME\tools\msys64\usr\bin\sh-bak.exe $env:JTSDK_HOME\tools\msys64\usr\bin\sh.exe | Out-Null 
}

Push-Location $env:JTSDK_HOME\tools\msys64\usr\bin
Rename-Item $env:JTSDK_HOME\tools\msys64\usr\bin\sh.exe $env:JTSDK_HOME\tools\msys64\usr\bin\sh-bak.exe | Out-Null
Pop-Location

# Process Options ------------------------------------------------ PROCESS OPTIONS
# This processes the options behind the command jtbuild

if ($args -ne $null) { $aarg = [string]$args } else { $aarg=$null }
$copt="Release"
$topt="Config"
ProcessOptions $aarg -rcopt ([ref]$copt) -rtopt ([ref]$topt)	

# Reads in configuration data from Versions.ini ------------------ PROCESS key data from Versions.ini

$env:jtsdk64VersionConfig = "$env:JTSDK_CONFIG\Versions.ini"
Get-Content $env:jtsdk64VersionConfig | foreach-object -begin {$configTable=@{}} -process { $k = [regex]::split($_,'='); if(($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True)) { $configTable.Add($k[0], $k[1]) } }

$srcd = $configTable.Get_Item("srcd")				# Sets srcd => Source Location
$dest = $configTable.Get_Item("destd")				# Sets dest => Desctination Location
$cfgd = $env:JTSDK_CONFIG							# Sets cfgd => JTSDK_CONFIG location
$qtv = $env:QTV										# Sets qtv => QTV

$cleanFirst="No"
$cleanFirst=$configTable.Get_Item("cleanfirst")		# Clean First Flag 

$reconfigure="No"
$reconfigure=$configTable.Get_Item("reconfigure")	# Reconfigure Flag

$autorun="No"
$autorun= $configTable.Get_Item("autorun")			# Autorun Flag

$JJ=$env:NUMBER_OF_PROCESSORS						# Read from ENV; Can set mamnually

# Display Build Commencement Message ----------------------------- COMMENCE BUILD

CommenceBuild ($env:JT_SRC)

# Download source based on switch in $cfgd ----------------------- DOWNLOAD SOURCE
# Switch is src-wsjtx, src-jtdx or src-js8call

DownloadSource($srcd)

# QT CMake Tool Chain File Selection # --------------------------- QT TOOLCHAIN

$pathDPDel = $env:QTV
$pathDPDelR = $pathDPDel -replace "\.",''
$tchain = ($env:JTSDK_TOOLS + "\tc-files\QT"+$pathDPDelR+".cmake").replace("\","/")

# Set Version Data  ---------------------------------------------- SET VERSION DATA

[Int]$mav = 0  # Major Version
[Int]$miv = 0  # Minor Version
[Int]$pav = 0  # Patch Version
[Int]$rcx = 0  # Release Candidate Nbr  
[Int]$relx = 0 # Release flag

GetVersionData -rmav ([ref]$mav) -rmiv ([ref]$miv) -rpav ([ref]$pav) -rrcx ([ref]$rcx) -rrelx([ref]$relx)

$aver="$mav.$miv.$pav"
$desc="Development"
if ($relx -eq 1) { $desc="GA Release" }
if (($relx -gt 0) -and ($relx -eq 1)) { $desc="GA Release" }
if (($relx -eq 0) -and ($relx -eq 0)) { $desc="Development" }
if (($relx -gt 0) -and ($relx -eq 0)) { $desc="Release Candidate" }

# Setup Directories ---------------------------------------------- SETUP DIRECTORIES

$buildd="$dest\qt\$qtv\$aver\$copt\build"
$installd="$dest\qt\$qtv\$aver\$copt\install"
$pkgd="$dest\qt\$qtv\$aver\$copt\package"
SetupDirectories

# Build Information ---------------------------------------------- BUILD INFORMATION

BuildInformation

# select build type ---------------------------------------------- BUILD SELECT

if ($topt -like "Config") { ConfigOnly }
if ($topt -like "Install") { InstallTarget }
if ($topt -like "Package") { PackageTarget }
if ($topt -like "Docs") { DocsTarget } 

# ---------------------------------------------------------------- FINAL CATCH-ALL !!!
GenerateError("Undefined Target")

TheEnd (-1)
