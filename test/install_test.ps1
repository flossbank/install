#!/usr/bin/env pwsh

$ErrorActionPreference = 'Stop'

# set staging api endpoint so we can use bogus install token
$LinuxConfigPath = if ($XDG_CONFIG_HOME) {
  Join-Path $XDG_CONFIG_HOME ".config" "flossbank-nodejs"
} else {
  Join-Path $Home ".config" "flossbank-nodejs"
}
$MacConfigPath = Join-Path $Home "Library" "Preferences" "flossbank-nodejs"
$WinConfigPath = Join-Path $Home "AppData" "Roaming" "flossbank-nodejs" "Config"
New-Item $LinuxConfigPath -ItemType Directory | Out-Null
New-Item $MacConfigPath -ItemType Directory | Out-Null
New-Item $WinConfigPath -ItemType Directory | Out-Null
$LinuxConfig = Join-Path $LinuxConfigPath "config.json"
$MacConfig = Join-Path $MacConfigPath "config.json"
$WinConfig = Join-Path $WinConfigPath "config.json"
Write-Output '{"apiHost":"https://api.flossbank.io"}' > $LinuxConfig
Write-Output '{"apiHost":"https://api.flossbank.io"}' > $MacConfig
Write-Output '{"apiHost":"https://api.flossbank.io"}' > $WinConfig

$env:FLOSSBANK_INSTALL_TOKEN = "cf667c9381f7792bfa772025ff8ee93b89d9a757e6732e87611a0c34b48357d1"

# install the latest version at the default location
$DefaultLocation = Join-Path $Home ".flossbank"
Remove-Item -Force -Recurse $DefaultLocation
$FLOSSBANK_INSTALL = ""
.\install.ps1
$Exe = Join-Path $DefaultLocation "bin" "flossbank"
Start-Process $Exe -Wait -NoNewWindow -PassThru

# install to a custom location
$CustomLocation = Join-Path $Home "flossbank-custom"
Remove-Item -Force -Recurse $CustomLocation
$FLOSSBANK_INSTALL = $CustomLocation
.\install.ps1
$Exe = Join-Path $CustomLocation "bin" "flossbank"
Start-Process $Exe -Wait -NoNewWindow -PassThru
