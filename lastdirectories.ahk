#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
#SingleInstance force
#Persistent ;Script nicht beenden nach der Auto-Execution-Section
;@Ahk2Exe-ExeName %A_ScriptDir%\bin\FmanSaveAsDialogExtension\SaveAsDialogExtension\lastdirectories.exe

SetWorkingDir %A_ScriptDir%
SetTitleMatchMode, 2


Menu, tray, NoStandard
Menu, tray, add  ; Creates a separator line.
Menu, tray, add, Reload  
Menu, tray, add, Exit

#Include JSON.ahk

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

Action:	
	path = %A_AppData%\fman\plugins\User\Settings\Lastdirectories (Windows).json
	FileRead, jsonString, %path%
	json := JSON.Load(jsonString)

	dataArray := []
	for each, item in json
		dataArray.push(item)

	dataArray := ReverseArray(dataArray)

	stringOutput = 
	counter := 1
	for each, item in dataArray 
	{
		stringOutput = %stringOutput%%counter%: %item%`n
		counter++
		if(counter > 9) {
			break
		}
	}

	ToolTip, %stringOutput%
	Input , inputVar, L1
	targetDir := dataArray[inputVar]
	ToolTip,

	ControlSetText, Edit1,%targetDir%, A
	Sleep, 10
	ControlSend Edit1, {Enter}
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