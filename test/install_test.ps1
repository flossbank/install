#!/usr/bin/env pwsh

$ErrorActionPreference = 'Stop'

# set staging api endpoint so we can use bogus install token
$LinuxConfigPath = if ($env:XDG_CONFIG_HOME) {
  Join-Path -Path "$env:XDG_CONFIG_HOME" -ChildPath ".config" | Join-Path -ChildPath "flossbank-nodejs"
} else {
  Join-Path -Path "$Home" -ChildPath ".config" | Join-Path -ChildPath "flossbank-nodejs"
}
$MacConfigPath = Join-Path -Path "$Home" -ChildPath "Library" | Join-Path -ChildPath "Preferences" | Join-Path -ChildPath "flossbank-nodejs"
$WinConfigPath = Join-Path -Path "$Home" -ChildPath "AppData" | Join-Path -ChildPath "Roaming" | Join-Path -ChildPath "flossbank-nodejs" | Join-Path -ChildPath "Config"
New-Item $LinuxConfigPath -Force -ItemType Directory | Out-Null
New-Item $MacConfigPath -Force -ItemType Directory | Out-Null
New-Item $WinConfigPath -Force -ItemType Directory | Out-Null
$LinuxConfig = Join-Path -Path "$LinuxConfigPath" -ChildPath "config.json"
$MacConfig = Join-Path -Path "$MacConfigPath" -ChildPath "config.json"
$WinConfig = Join-Path -Path "$WinConfigPath" -ChildPath "config.json"
Write-Output '{"apiHost":"https://api.flossbank.io"}' > $LinuxConfig
Write-Output '{"apiHost":"https://api.flossbank.io"}' > $MacConfig
Write-Output '{"apiHost":"https://api.flossbank.io"}' > $WinConfig

$env:FLOSSBANK_INSTALL_TOKEN = "cf667c9381f7792bfa772025ff8ee93b89d9a757e6732e87611a0c34b48357d1"

# install the latest version at the default location
$DefaultLocation = Join-Path $Home ".flossbank"
if (Test-Path $DefaultLocation) {
  Remove-Item -Force -Recurse $DefaultLocation
}
$env:FLOSSBANK_INSTALL = ""
.\install.ps1
$Exe = Join-Path -Path $DefaultLocation -ChildPath "bin" | Join-Path -ChildPath "flossbank"
Start-Process $Exe -Wait -NoNewWindow -PassThru

# install to a custom location
$CustomLocation = Join-Path $Home "flossbank-custom"
if (Test-Path $CustomLocation) {
  Remove-Item -Force -Recurse $CustomLocation
}
$env:FLOSSBANK_INSTALL = $CustomLocation
.\install.ps1
$Exe = Join-Path -Path $CustomLocation -ChildPath "bin" | Join-Path -ChildPath "flossbank"
Start-Process $Exe -Wait -NoNewWindow -PassThru
