;@Ahk2Exe-SetMainIcon icon.ico

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
#SingleInstance force
#Persistent ;Script nicht beenden nach der Auto-Execution-Section
;@Ahk2Exe-ExeName %A_ScriptDir%\saveasdialogextension\lastdirectories.exe

SetWorkingDir %A_ScriptDir%
SetTitleMatchMode, 2

if (!a_iscompiled) {
	Menu, tray, icon, icon.ico,0,1
}

Menu, tray, NoStandard
Menu, tray, add  ; Creates a separator line.
Menu, tray, add, Reload  
Menu, tray, add, Exit

; #Include JSON.ahk  ; Not needed - using manual parsing

ActiveHWND = 
SetTimer, CheckForFman, 10000

return

CheckForFman:
	Process, Exist, fman.exe
    if !ErrorLevel
	 ExitApp
return

F9::
	ActiveHWND  := WinActive("A")
	WinGetClass, CurrentClass, ahk_id %ActiveHWND%

	If (CurrentClass="#32770")
	{
		GoSub, Action
	}
	else
	{
		Send, {Raw}F9
	}	 
return

AltD_Works(win := "A") {
    WinActivate, %win%
    ClipSaved := ClipboardAll
    Clipboard := ""
    Send, !d
    Sleep, 120
    Send, ^a^c
    ClipWait, 0.3
    txt := Trim(Clipboard, " `t`r`n""")
    Clipboard := ClipSaved
    if (txt = "")
        return false

    ; accept real paths OR common shell labels
    if RegExMatch(txt, "i)^(?:[A-Z]:\\|\\\\)")          ; drive/UNC
        return true
    if RegExMatch(txt, "i)^(Downloads|Desktop|Documents|Pictures|Music|Videos|OneDrive|This PC|Quick access)$")
        return true

    return InStr(FileExist(txt), "D")                    ; last fallback
}

PastePath(winID, targetDir) {
    ; ensure trailing backslash
    targetDir := RTrim(targetDir, "\/") . "\"

    WinActivate, ahk_id %winID%
    ClipSaved := ClipboardAll
    Clipboard := ""
    Clipboard := targetDir
    ClipWait, 0.3

    Send, !d           ; focus address bar / filename box
    Sleep, 80
    Send, ^v{Enter}

    Sleep, 120
    Clipboard := ClipSaved
}


Action:
	; Clean up any existing state
	Gui, DirectoryList:Destroy
	dataArray := []
	tempArray := []
	json := ""  ; Clear json variable

	path = %A_AppData%\fman\plugins\User\Settings\SaveAsDialog_Lastdirectories (Windows).json
	FileRead, jsonString, %path%

	; Check if file read succeeded
	if (ErrorLevel) {
		MsgBox, Failed to read file: %path%
		return
	}

	; Manual JSON parsing for simple array format: ["path1", "path2", "path3"]
	; Clean the JSON string
	StringReplace, jsonString, jsonString, `r, , All
	StringReplace, jsonString, jsonString, `n, , All
	jsonString := Trim(jsonString)

	; Parse manually - remove brackets and split by commas
	jsonLen := StrLen(jsonString)
	if (SubStr(jsonString, 1, 1) = "[" && SubStr(jsonString, jsonLen, 1) = "]") {
		; Remove the surrounding brackets
		jsonContent := SubStr(jsonString, 2, StrLen(jsonString) - 2)

		; Split by comma and parse each quoted string
		dataArray := []
		seenPaths := {}

		; Simple state machine to parse quoted strings
		currentPath := ""
		inQuotes := false
		i := 1

		while (i <= StrLen(jsonContent)) {
			char := SubStr(jsonContent, i, 1)

			if (char = """" && !inQuotes) {
				; Start of quoted string
				inQuotes := true
				currentPath := ""
			} else if (char = """" && inQuotes) {
				; End of quoted string
				inQuotes := false
				; Process the completed path
				if (currentPath != "") {
					; Skip FTP paths and drives: paths
					if (InStr(currentPath, "ftp:/") != 1 && InStr(currentPath, "drives:") != 1) {
						; Normalize path for comparison (remove trailing slashes)
						normalizedPath := RTrim(currentPath, "\/")
						if (!seenPaths.HasKey(normalizedPath)) {
							dataArray.Push(currentPath)
							seenPaths[normalizedPath] := true
						}
					}
				}
				currentPath := ""
			} else if (inQuotes) {
				; Inside quotes, add character (handle escape sequences)
				if (char = "\") {
					; Handle escape sequences
					nextChar := SubStr(jsonContent, i + 1, 1)
					if (nextChar = "\") {
						currentPath .= "\"
						i++ ; Skip next character
					} else if (nextChar = """") {
						currentPath .= """"
						i++ ; Skip next character
					} else {
						currentPath .= char
					}
				} else {
					currentPath .= char
				}
			}
			i++
		}

		; Reverse the array for display (most recent first)
		dataArray := ReverseArray(dataArray)

	} else {
		MsgBox, Invalid JSON format - not an array
		return
	}

	; Create minimalistic GUI
	Gui, DirectoryList:New, +AlwaysOnTop -Caption +ToolWindow +Border
	Gui, DirectoryList:Color, 2b2b2b
	Gui, DirectoryList:Font, s11 cE8E8E8, Segoe UI
	Gui, DirectoryList:Margin, 18, 12

	; Add title
	Gui, DirectoryList:Font, s9 c999999
	Gui, DirectoryList:Add, Text, w450 Center, Recent Directories (1-9 or ESC to cancel)
	Gui, DirectoryList:Font, s11 cE8E8E8

	counter := 1
	for each, item in dataArray
	{
		; Truncate long paths for display
		displayPath := item
		if (StrLen(displayPath) > 55)
			displayPath := "..." . SubStr(displayPath, -52)

		Gui, DirectoryList:Add, Text, w450, %counter%:  %displayPath%
		counter++
		if(counter > 9) {
			break
		}
	}

	; Position GUI centered in the save dialog
	WinGetPos, winX, winY, winW, winH, ahk_id %ActiveHWND%
	guiX := winX + (winW - 486) / 2  ; 486 = 450 + 2*18 margin
	guiY := winY + (winH - 250) / 2  ; Approximate GUI height
	Gui, DirectoryList:Show, x%guiX% y%guiY% NoActivate

	; Wait for input
	Input, inputVar, L1 T5, {Escape}

	; Close GUI
	Gui, DirectoryList:Destroy

	; Check if cancelled
	if (ErrorLevel = "EndKey:Escape") {
		return
	}

	; Process selection
	if (inputVar < 1 || inputVar > 9 || !dataArray[inputVar]) {
		return
	}

	targetDir := dataArray[inputVar]
	; ensure exactly one trailing backslash
	targetDir := RTrim(targetDir, "\/") . "\"

	if AltD_Works("ahk_id " ActiveHWND) {
		;SendInput, %targetDir%
		;Send, {Enter}
		PastePath(ActiveHWND, targetDir)
	}  else {
		if !WinActive("ahk_id " ActiveHWND)  ; re-assert focus if needed
			WinActivate, ahk_id %ActiveHWND%
		ControlFocus, Edit2, ahk_id %ActiveHWND%
		ControlSetText, Edit2, %targetDir%, ahk_id %ActiveHWND%
		;ControlSend,  Edit2, {Enter}, ahk_id %ActiveHWND%
		
		;ControlSetText, Edit2,%targetDir%, A
		;Sleep, 10
		;ControlSend Edit2, {Enter}
	}
	Sleep, 100
	ControlFocus, Edit1, ahk_id %ActiveHWND%
	Sleep, 100
return

ReverseArray(oArray)
{
	Array := Object()
	For i,v in oArray
		Array[oArray.Length()-i+1] := v
	Return Array
}


Reload:
	Reload
return 

Exit:
	ExitApp
return

if(!A_IsCompiled) {
	#y::
		Send ^s
		reload
	return
}