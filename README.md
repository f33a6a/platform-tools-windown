# platform-tools-windown
just an automated pwsh script to download and add platform tools to env


## Quick Installation

Run this command in PowerShell (Run as Administrator):

```powershell
powershell -Command "& {Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/f33a6a/platform-tools-windows/main/install.ps1' -OutFile "$env:TEMP\install-pt.ps1"; Start-Process powershell.exe -ArgumentList '-ExecutionPolicy', 'Bypass', '-File', "$env:TEMP\install-pt.ps1" -Verb RunAs}"
