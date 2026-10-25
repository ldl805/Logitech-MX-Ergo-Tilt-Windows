# Logitech-MX-Ergo-Tilt-Windows

A lightweight, zero-bloatware Windows utility that remaps the **Logitech MX Ergo** horizontal scroll wheel tilt (**Tilt Left** / **Tilt Right**) to browser/system **Back** (`XBUTTON1`) and **Forward** (`XBUTTON2`) without installing Logitech Options or Logi Options+.

## Features
- **Zero Bloatware**: Compiled to a tiny (~6 KB) native Windows executable using built-in Win32 low-level mouse hooks (`WH_MOUSE_LL`). Uses virtually zero CPU and RAM.
- **Tilt Left / Right Navigation**:
  - **Tilt Wheel Left** $\rightarrow$ **Back** (`XBUTTON1`)
  - **Tilt Wheel Right** $\rightarrow$ **Forward** (`XBUTTON2`)
- **Clean Event Swallowing**: Suppresses the default horizontal scroll (`WM_MOUSEHWHEEL`) event so tilting the wheel doesn't accidentally scroll pages sideways while navigating back or forward.
- **Smart Debounce Cooldown**: Includes a 300ms debounce timer so holding the tilt wheel slightly too long triggers a single navigation action rather than rapid-firing through your history.
- **System-Wide & Auto-Start**: Runs silently at Windows logon via Task Scheduler with highest privileges so it works seamlessly across all browsers (Firefox, Chrome, Edge), File Explorer, and even Administrator windows.

## Installation

### Option 1: Windows Installer (Recommended)

Download the latest `Logitech-MX-Ergo-Tilt-Windows-Setup-v1.0.0.exe` from the [Releases](../../releases) page and run it.

The installer automatically:
1. Installs `MxErgoTiltRemap.exe` to `%LOCALAPPDATA%\MxErgoTiltRemap`.
2. Registers and starts the background Windows Scheduled Task (`MxErgoTiltRemap`) to run at logon.
3. Registers an entry in Windows **Installed Apps** (Add/Remove Programs) for easy uninstallation.

### Option 2: Run / Build from Source

No third-party compilers or SDKs are required—it compiles out of the box on any Windows 10/11 PC using the built-in .NET Framework compiler.

1. Clone the repository:
   ```powershell
   git clone https://github.com/ldl805/Logitech-MX-Ergo-Tilt-Windows.git
   cd Logitech-MX-Ergo-Tilt-Windows
   ```
2. Run the PowerShell installer (as Administrator):
   ```powershell
   .\install.ps1
   ```

#### Optional Parameters
- **Invert directions** (Tilt Left = Forward, Tilt Right = Back):
  ```powershell
  .\install.ps1 -Invert
  ```
- **Custom debounce cooldown** (in milliseconds, default `300`):
  ```powershell
  .\install.ps1 -CooldownMs 250
  ```
- **Uninstall**:
  ```powershell
  .\install.ps1 -Uninstall
  ```

## Building the Release Installer

If you have [NSIS](https://nsis.sourceforge.io/) installed, run:
```powershell
.\build.ps1
```
This builds both the standalone `dist\MxErgoTiltRemap.exe` binary and the `dist\Logitech-MX-Ergo-Tilt-Windows-Setup-v1.0.0.exe` installer.

## License
MIT License
