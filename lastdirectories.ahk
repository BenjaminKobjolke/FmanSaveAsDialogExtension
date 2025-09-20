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

#Include JSON.ahk

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
	path = %A_AppData%\fman\plugins\User\Settings\SaveAsDialog_Lastdirectories (Windows).json
	FileRead, jsonString, %path%
	json := JSON.Load(jsonString)

	tempArray := []
	seenPaths := {}
	for each, item in json {
		; Skip FTP paths
		if (InStr(item, "ftp:/") = 1)
			continue

		; Normalize path for comparison (remove trailing slashes)
		normalizedPath := RTrim(item, "\/")
		if (!seenPaths.HasKey(normalizedPath)) {
			tempArray.push(item)
			seenPaths[normalizedPath] := true
		}
	}

	; Create a fresh dataArray from reversed tempArray
	dataArray := ReverseArray(tempArray)

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

	; Position GUI near mouse
	MouseGetPos, mouseX, mouseY
	Gui, DirectoryList:Show, x%mouseX% y%mouseY% NoActivate

	; Wait for input
	Input, inputVar, L1 T5, {Escape}

	; Close GUI
	Gui, DirectoryList:Destroy

	; Check if cancelled
	if (ErrorLevel = "EndKey:Escape") {
		reload
		return
	}

	; Process selection
	if (inputVar < 1 || inputVar > 9 || !dataArray[inputVar]) {
		reload
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
	reload
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