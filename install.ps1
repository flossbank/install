#!/usr/bin/env pwsh
# TODO(everyone): Keep this script simple and easily auditable.
# Thanks deno.land for inspiration <3
#
#    Copyright (C) 2020 Flossbank, Inc.
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

$ErrorActionPreference = 'Stop'

$FlossbankInstall = $env:FLOSSBANK_INSTALL
if (!$FlossbankInstall) {
  $FlossbankInstall = Join-Path -Path "$Home" -ChildPath ".flossbank"
}

if ($PSVersionTable.PSEdition -ne 'Core' -Or $IsWindows) {
  # if not using PowerShell Core, we must be on Windows PowerShell
  # if we are using PowerShell Core, $IsWindows should be exposed
  $Target = 'win-x86_64'
  $ExeName = 'flossbank.exe'
} else {
  $ExeName = 'flossbank'
  $Target = if ($IsMacOS) {
    'macos-x86_64'
  } else {
    'linux-x86_64'
  }
}

$BinDir = Join-Path -Path "$FlossbankInstall" -ChildPath "bin"
$FlossbankZip = Join-Path -Path "$BinDir" -ChildPath "flossbank.zip"
$FlossbankExe = Join-Path -Path "$BinDir" -ChildPath "$ExeName"

$FlossbankInstallToken = $env:FLOSSBANK_INSTALL_TOKEN
if (!(Test-Path $FlossbankExe)) {
  $needInstallToken = $True
} else {
  $check = Start-Process $FlossbankExe -ArgumentList "check" -Wait -NoNewWindow -PassThru
  $needInstallToken = $check.ExitCode -ne 0
}
if ($needInstallToken -And !$FlossbankInstallToken) {
  $FlossbankInstallToken = Read-Host -Prompt 'Please enter install token to continue: '
}

Write-Output ""
Write-Output "Welcome to Flossbank!"
Write-Output ""
Write-Output "This script will download and install the latest version of Flossbank,"
Write-Output "a package manager wrapper that helps compensate open source maintainers."
Write-Output ""
Write-Output "It will add the 'flossbank' command to Flossbank's bin directory, located at:"
Write-Output ""
Write-Output "$BinDir"
Write-Output ""
Write-Output "This path will then be added to your PATH environment variable by"
Write-Output "modifying your shell profile/s."
Write-Output ""
Write-Output "You can uninstall at any time by executing 'flossbank uninstall'"
Write-Output "and these changes will be reverted."
Write-Output ""

if (!$env:FLOSSBANK_CONFIRM) {
	Read-Host -Prompt 'Press return key to continue...'
}

$Response = Invoke-WebRequest "https://install.flossbank.com/releases/$Target" -UseBasicParsing
if (!$Response) {
  Write-Output ""
  Write-Output "Error: unable to locate latest release on GitHub. Please try again or email support@flossbank.com for help!"
  return
}
$FlossbankAssetInfo = $Response.Content

$FlossbankUri = $FlossbankAssetInfo.Split("`n")[0]
$FlossbankVersion = $FlossbankAssetInfo.Split("`n")[1]
$FlossbankFileName = $FlossbankUri.Split("/")[8]

if (!(Test-Path $BinDir)) {
  New-Item $BinDir -ItemType Directory | Out-Null
}

Write-Output "Installing version: $FlossbankVersion"
Write-Output "  - Downloading $FlossbankFileName..."

# GitHub requires TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest $FlossbankUri -OutFile $FlossbankZip -UseBasicParsing
Expand-Archive $FlossbankZip -Destination $BinDir -Force
Remove-Item $FlossbankZip
if ($IsMacOS -Or $IsLinux) {
  chmod +x "$FlossbankExe"
}

Write-Output ""
$InstallArgs = "install", "`"$FlossbankInstall`""
$WrapArgs = "wrap", "all"
$AuthArgs = "auth", "$FlossbankInstallToken"

$installCall = Start-Process $FlossbankExe -ArgumentList $InstallArgs -Wait -NoNewWindow -PassThru
$wrapCall = Start-Process $FlossbankExe -ArgumentList $WrapArgs -Wait -NoNewWindow -PassThru
if ($needInstallToken) {
  $authCall = Start-Process $FlossbankExe -ArgumentList $AuthArgs -Wait -NoNewWindow -PassThru
}
Write-Output ""

$authSuccess = ($authCall.ExitCode -eq 0) -Or !$needInstallToken
if ($installCall.ExitCode -ne 0 -Or $wrapCall.ExitCode -ne 0 -Or !$authSuccess) {
  Write-Output ""
  Write-Output "Oh no :( we had trouble setting up Flossbank. Please try again or email support@flossbank.com for help!"
  return
}

$envFile = Join-Path -Path "$FlossbankInstall" -ChildPath "env.ps1"
. $envFile

Write-Output ""
Write-Output "Flossbank ($FlossbankVersion) is now installed and registered. Great!"
Write-Output ""
