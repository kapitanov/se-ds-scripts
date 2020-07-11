#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
$INSTALL_LOCATION = Join-Path $(pwd) "SpaceEngineersDedicated"
$SE_INSTALL_LOCATION = Join-Path $INSTALL_LOCATION "Server"
$STEAMCMD_INSTALL_LOCATION = Join-Path $INSTALL_LOCATION "SteamCMD"
$STEAMCMD_INSTALL_SOURCE = "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip"
$SE_APP_ID = "298740"

$STEAMCMD = Join-Path $STEAMCMD_INSTALL_LOCATION "SteamCMD.exe"
$SE_EXE = Join-Path $SE_INSTALL_LOCATION "DedicatedServer64/SpaceEngineersDedicated.exe"
$UPDATE_SCRIPT = Join-Path $INSTALL_LOCATION "update-se-ds.ps1"

function Ensure-DirectoryExists($dir) {
	if (-not (Test-Path $dir)) {
		New-Item $dir -ItemType Directory -ErrorAction Stop | Out-Null
	}
	$dir = Split-Path $dir
	if (-not ([string]::IsNullOrEmpty($dir))) {
		Ensure-DirectoryExists $dir
	}
}

function Install-SteamCMD() {
	Write-Host "Installing SteamCMD" -f cyan
	Ensure-DirectoryExists $STEAMCMD_INSTALL_LOCATION
	if (Test-Path $STEAMCMD) {
		Write-Host "SteamCMD is already installed"
		return
	}

	$STEAMCMD_ZIP = Join-Path $INSTALL_LOCATION "SteamCMD.zip"
	Invoke-WebRequest -Uri $STEAMCMD_INSTALL_SOURCE -OutFile $STEAMCMD_ZIP -UseBasicParsing -ErrorAction Stop
	Expand-Archive -Path $STEAMCMD_ZIP -DestinationPath $STEAMCMD_INSTALL_LOCATION -Force -ErrorAction Stop
	Remove-Item $STEAMCMD_ZIP -Force -ErrorAction Stop
}

function Install-SpaceEngineersDS() {
	Ensure-DirectoryExists $SE_INSTALL_LOCATION
	& $STEAMCMD +@ShutdownOnFailedCommand 1 +force_install_dir $SE_INSTALL_LOCATION +login Anonymous +app_update $SE_APP_ID +quit
	if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 7) {
		Write-Host "Unable to install Space Engineers Dedicated Server!" -f red
		Write-Host "SteamCMD exit code: $LASTEXITCODE" -f red
		exit 1
	}
}

function Configure-WindowsFirewall() {
	Import-Module NetSecurity

	New-NetFirewallRule -DisplayName "Space Engineers DS (UDP 27016)" -Direction Inbound `
		-LocalPort 27016 -Protocol UDP -Action Allow -ErrorAction Stop | Out-Null
	Write-Host "Defined firewall rule `"Space Engineers DS (UDP 27016)`""

	New-NetFirewallRule -DisplayName "Space Engineers DS (UDP 27017)" -Direction Inbound `
		-LocalPort 27017 -Protocol UDP -Action Allow -ErrorAction Stop | Out-Null
	Write-Host "Defined firewall rule `"Space Engineers DS (UDP 27017)`""

	New-NetFirewallRule -DisplayName "Space Engineers DS (any)" -Direction Inbound `
		-Program "$SE_EXE" -Action Allow -ErrorAction Stop | Out-Null
	Write-Host "Defined firewall rule `"Space Engineers DS (any)`""
}

function Install-ManagementScripts() {
	Write-Output "#!/usr/bin/env pwsh" > $UPDATE_SCRIPT
	Write-Output "`$ErrorActionPreference = `"Stop`"" >> $UPDATE_SCRIPT
	Write-Output "" >> $UPDATE_SCRIPT
	Write-Output "`$SE_STEAMCMD_EXE = `"$STEAMCMD`"" >> $UPDATE_SCRIPT
	Write-Output "`$SE_INSTALL_LOCATION = `"$SE_INSTALL_LOCATION`"" >> $UPDATE_SCRIPT
	Write-Output "`$SE_APP_ID = `"$SE_APP_ID`"" >> $UPDATE_SCRIPT
	Write-Output "" >> $UPDATE_SCRIPT
	Write-Output "& `$SE_STEAMCMD_EXE +@ShutdownOnFailedCommand 1 +force_install_dir `$SE_INSTALL_LOCATION +login Anonymous +app_update $SE_APP_ID +quit" >> $UPDATE_SCRIPT
	Write-Output "if (`$LASTEXITCODE -ne 0) {" >> $UPDATE_SCRIPT
	Write-Output "  Write-Host `"Unable to update Space Engineers Dedicated Server!`" -f red" >> $UPDATE_SCRIPT
	Write-Output "  Write-Host `"SteamCMD exited with error `$LASTEXITCODE`" -f red" >> $UPDATE_SCRIPT
	Write-Output "  exit 1" >> $UPDATE_SCRIPT
	Write-Output "}" >> $UPDATE_SCRIPT
	Write-Output "" >> $UPDATE_SCRIPT
	Write-Host "Generated `"$UPDATE_SCRIPT`""
}

function Install-Shortcuts() {
	$WshShell = New-Object -comObject WScript.Shell
	$shortcut = $WshShell.CreateShortcut("$($Home)\Desktop\Start SpaceEngineers DS.lnk")
	$shortcut.TargetPath = $SE_EXE
	$shortcut.Arguments = $ArgumentsToSourceExe
	$shortcut.WorkingDirectory = $SE_INSTALL_LOCATION
	$shortcut.Save()
	Write-Host "Created `"Start SpaceEngineers DS`" shortcut"

	$shortcut = $WshShell.CreateShortcut("$($Home)\Desktop\Update SpaceEngineers DS.lnk")
	$shortcut.TargetPath = $(get-command powershell).source
	$shortcut.Arguments = "-NoLogo -File `"$UPDATE_SCRIPT`" -NoExit"
	$shortcut.WorkingDirectory = $INSTALL_LOCATION
	$shortcut.Save()
	Write-Host "Created `"Update SpaceEngineers DS`" shortcut"
}

# -----------------------------------------------------------------------------
# Install SteamCMD
# -----------------------------------------------------------------------------
Install-SteamCMD

# -----------------------------------------------------------------------------
# Install Space Engineers Dedicated Server
# -----------------------------------------------------------------------------
Write-Host "Installing Space Engineers Dedicated Server" -f cyan
Install-SpaceEngineersDS

# -----------------------------------------------------------------------------
# Configure Windows Firewall
# -----------------------------------------------------------------------------
Write-Host "Configuring Windows Firewall" -f cyan
Configure-WindowsFirewall

# -----------------------------------------------------------------------------
# Install management scripts
# -----------------------------------------------------------------------------
Write-Host "Installing management scripts" -f cyan
Install-ManagementScripts

# -----------------------------------------------------------------------------
# Install shortcuts
# -----------------------------------------------------------------------------
Write-Host "Installing shortcuts" -f cyan
Install-Shortcuts

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------
Write-Host "OK, Space Engineers Dedicated Server is installed" -f green
& $profile | Out-Null
