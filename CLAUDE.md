# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an fman plugin that enhances Windows save/open dialogs with directory history from fman. It consists of:
- A Python plugin component that tracks directory navigation in fman
- An AutoHotkey executable that provides system-wide hotkey functionality

## Build Commands

```batch
# Build the AutoHotkey executable
"c:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" /in lastdirectories.ahk
move /y lastdirectories.exe saveasdialogextension\lastdirectories.exe
```

Or use the build script:
```batch
build_release.bat
```

## Architecture

### Core Components

1. **Python Plugin** (`saveasdialogextension/__init__.py`):
   - Monitors fman directory changes via `OnDirectoryChanged` listener
   - Saves last 9 directories to `SaveAsDialog_Lastdirectories.json`
   - Auto-launches `lastdirectories.exe` on first directory change
   - Uses fman API for directory tracking and JSON storage

2. **AutoHotkey Application** (`lastdirectories.ahk`):
   - Compiled to `saveasdialogextension/lastdirectories.exe`
   - Runs in system tray with custom icon
   - Monitors for fman.exe process every 10 seconds, exits if not found
   - Intercepts F9 key in Windows save/open dialogs (class #32770)
   - Reads directory history from fman's settings JSON
   - Displays numbered tooltip menu (1-9) for quick directory selection

3. **JSON Library** (`JSON.ahk`):
   - Third-party JSON parsing library for AutoHotkey
   - Handles reading fman's JSON settings file

### Data Flow

1. User navigates directories in fman → Python plugin captures path
2. Path saved to JSON file in fman settings folder
3. User presses F9 in save/open dialog → AutoHotkey reads JSON
4. AutoHotkey displays tooltip with last 9 directories
5. User presses 1-9 → Dialog navigates to selected directory

### Key File Locations

- Plugin installation: `%AppData%\Roaming\fman\Plugins\User\FmanSaveAsDialogExtension`
- Settings file: `%AppData%\fman\plugins\User\Settings\SaveAsDialog_Lastdirectories.json`
- Windows dialog settings: `%AppData%\fman\plugins\User\Settings\Lastdirectories (Windows).json`

## Development Notes

- **IMPORTANT**: Always use AutoHotkey v1 syntax when modifying `lastdirectories.ahk`
- AutoHotkey compiler required at: `c:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe`
- Plugin requires `win32api` Python module for Windows-specific functionality
- `#SingleInstance force` ensures only one instance of the AutoHotkey app runs
- The AutoHotkey app automatically exits when fman.exe is no longer running