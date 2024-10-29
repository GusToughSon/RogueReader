#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=RogueReader.ico
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_Res_Description=Trainer for Project Rogue
#AutoIt3Wrapper_Res_Fileversion=0.0.0.14
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_ProductName=Rogue Reader
#AutoIt3Wrapper_Res_CompanyName=Macro Is Fun .LLC
#AutoIt3Wrapper_Res_LegalTradeMarks=Macro Is Fun .LLC
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Run_Tidy=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include "NomadMemory.au3"
#include <GUIConstantsEx.au3>
#include <File.au3>
#include <JSON.au3>
#include <Misc.au3>

Opt("MouseCoordMode", 2)

Global $version = FileGetVersion(@ScriptFullPath)
ConsoleWrite("Script Version: " & $version & @CRLF)

; --- Load Config Settings ---
Global $HealHotkey = "{`}" ; Default Heal Hotkey
Global $ExitHotkey = "{/}" ; Default Exit Hotkey
LoadConfig()

; --- Set Hotkeys from Config ---
HotKeySet($HealHotkey, "Hotkeyshit")
HotKeySet($ExitHotkey, "KilledWithFire")
HotKeySet("{4}", "TrashHeap")
ConsoleWrite("Heal: " & $HealHotkey)
ConsoleWrite("Exit: " & $ExitHotkey)
$Debug = False

; Define the game process and memory offsets
$ProcessName = "Project Rogue Client.exe"
$WindowName = "Project Rogue"
$TypeOffset = 0xBEFB04
$AttackModeOffset = 0xAC1D70
$PosXOffset = 0xBF2C70
$PosYOffset = 0xBF2C68
$HPOffset = 0x9BF988
$MaxHPOffset = 0x9BF98C
$ChattOpenOffset = 0x9B6998
$SicknessOffset = 0x9BFB68

Global $Running = True
Global $AttackModeAddress, $TypeAddress, $PosXAddress, $PosYAddress, $HPAddress, $MaxHPAddress, $ChattOpenAddress, $SicknessAddress, $MemOpen
Global $BaseAddress, $Type, $Chat

Global $currentTime = TimerInit(), $TargetDelay = 400, $HealDelay = 1700
Global $aMousePos = MouseGetPos()

; Create the GUI
$Gui = GUICreate("RougeReader " & "Version - " & $version, 400, 400, 15, 15)
$TypeLabel = GUICtrlCreateLabel("Type: N/A", 20, 30, 250, 20)
$AttackModeLabel = GUICtrlCreateLabel("Attack Mode: N/A", 20, 60, 250, 20)
$PosXLabel = GUICtrlCreateLabel("Pos X: N/A", 20, 90, 250, 20)
$PosYLabel = GUICtrlCreateLabel("Pos Y: N/A", 20, 120, 250, 20)
$HPLabel = GUICtrlCreateLabel("HP: N/A", 20, 150, 250, 20)
$ChatLabel = GUICtrlCreateLabel("Chat: N/A", 120, 150, 250, 20)
$HP2Label = GUICtrlCreateLabel("RealHp: N/A", 20, 180, 250, 20)
$SicknessLabel = GUICtrlCreateLabel("Sickness: N/A", 120, 180, 250, 20)
$MaxHPLabel = GUICtrlCreateLabel("MaxHP: N/A", 20, 210, 250, 20)
$HealerLabel = GUICtrlCreateLabel("Healer: OFF", 20, 240, 250, 20)
$HotkeyLabel = GUICtrlCreateLabel("Heal Hotkey: " & $HealHotkey & "   ExitProgramHotkey: " & $ExitHotkey, 20, 270, 350, 20)
$KillButton = GUICtrlCreateButton("Kill Rogue", 20, 300, 100, 30)
$ExitButton = GUICtrlCreateButton("Exit", 150, 300, 100, 30)
GUISetState(@SW_SHOW)

Global $HealerStatus = 0

; Main loop
While 1
	Global $ProcessID = ProcessExists($ProcessName)
	If $ProcessID Then
		ConnectToBaseAddress()
		If $BaseAddress = 0 Then
			Sleep(1000)
		Else
			ChangeAddressToBase()

			While $Running
				Local $elapsedTime = TimerDiff($currentTime)
				Local $msg = GUIGetMsg()

				If $msg = $ExitButton Or $msg = $GUI_EVENT_CLOSE Then
					_MemoryClose($MemOpen)
					GUIDelete($Gui)
					Exit
				EndIf
				If $msg = $KillButton Then
					ProcessClose($ProcessID)
					ExitLoop
				EndIf

				AttackModeReader()
				If $HealerStatus = 1 Then TimeToHeal()
				GUIReadMemory()

				Sleep(100)
			WEnd
		EndIf
	Else
		Sleep(1000)
	EndIf
WEnd

; Cleanup
GUIDelete($Gui)

Func LoadConfig()
	Local $configPath = @ScriptDir & "\Config.json"
	Local $defaultHealHotkey = "{1}"
	Local $defaultExitHotkey = "{/}"

	; Construct the default JSON configuration string in vertical format
	Local $defaultConfig = StringFormat('{\r\n    "HealHotkey": "{%s}",\r\n    "ExitHotkey": "{%s}"\r\n}', "1", "/")

	; Check if Config.json exists, if not, create it with default values
	If Not FileExists($configPath) Then
		FileWrite($configPath, $defaultConfig)
		ConsoleWrite("[Info] Config.json created with default hotkeys in correct format." & @CRLF)
	Else
		ConsoleWrite("[Info] Config.json found." & @CRLF)
	EndIf

	; Read the file and initialize variables
	Local $json = FileRead($configPath)
	If @error Then
		ConsoleWrite("[Error] Failed to read Config.json." & @CRLF)
		Return ; Exit function to avoid further errors
	EndIf

	ConsoleWrite("[Debug] Config.json content:\n" & $json & @CRLF)

	; Initialize variables with default values in case keys are missing
	$HealHotkey = $defaultHealHotkey
	$ExitHotkey = $defaultExitHotkey

	; Use regular expressions to extract hotkey values from JSON content
	Local $matchHeal = StringRegExp($json, '"HealHotkey"\s*:\s*"\{([^}]*)\}"', 1)
	Local $matchExit = StringRegExp($json, '"ExitHotkey"\s*:\s*"\{([^}]*)\}"', 1)

	; Set hotkeys from matched results, or keep defaults if not found
	If IsArray($matchHeal) Then $HealHotkey = "{" & $matchHeal[0] & "}"
	If IsArray($matchExit) Then $ExitHotkey = "{" & $matchExit[0] & "}"

	; Check if any hotkeys were missing and update the JSON file if necessary
	If Not IsArray($matchHeal) Or Not IsArray($matchExit) Then
		; Rebuild JSON with any missing values added
		$json = StringFormat('{\r\n    "HealHotkey": "%s",\r\n    "ExitHotkey": "%s"\r\n}', $HealHotkey, $ExitHotkey)
		FileWrite($configPath, $json)
		ConsoleWrite("[Info] Config.json updated with missing hotkeys." & @CRLF)
	EndIf

	; Set hotkeys in the script
	HotKeySet($HealHotkey, "Hotkeyshit")
	HotKeySet($ExitHotkey, "KilledWithFire")

	; Display loaded config settings for confirmation
	ConsoleWrite("[Config] HealHotkey set to: " & $HealHotkey & @CRLF)
	ConsoleWrite("[Config] ExitHotkey set to: " & $ExitHotkey & @CRLF)
EndFunc   ;==>LoadConfig


Func GUIReadMemory()
	If Not IsPtr($MemOpen) Then Return
	$Type = _MemoryRead($TypeAddress, $MemOpen, "dword")
;~ 	ConsoleWrite("[Debug] Type Memory Read: " & $Type & @CRLF) ; Debug line
	; Update the Type value in GUIReadMemory()
	If $Type = 0 Then
		GUICtrlSetData($TypeLabel, "Type: Player")
	ElseIf $Type = 1 Then
		GUICtrlSetData($TypeLabel, "Type: Monster")
	ElseIf $Type = 2 Then
		GUICtrlSetData($TypeLabel, "Type: NPC")
	ElseIf $Type = 65535 Then
		GUICtrlSetData($TypeLabel, "Type: No Target")
	Else
		GUICtrlSetData($TypeLabel, "Type: Unknown (" & $Type & ")") ; Handles unexpected values
	EndIf

	$PosX = _MemoryRead($PosXAddress, $MemOpen, "dword")
	GUICtrlSetData($PosXLabel, "Pos X: " & $PosX)

	$PosY = _MemoryRead($PosYAddress, $MemOpen, "dword")
	GUICtrlSetData($PosYLabel, "Pos Y: " & $PosY)

	$HP = _MemoryRead($HPAddress, $MemOpen, "dword")
	GUICtrlSetData($HPLabel, "HP: " & $HP)
	GUICtrlSetData($HP2Label, "RealHp: " & $HP / 65536)

	$MaxHP = _MemoryRead($MaxHPAddress, $MemOpen, "dword")
	GUICtrlSetData($MaxHPLabel, "MaxHP: " & $MaxHP)

	$Chat = _MemoryRead($ChattOpenAddress, $MemOpen, "dword")
	GUICtrlSetData($ChatLabel, "Chat: " & $Chat)

	$Sickness = _MemoryRead($SicknessAddress, $MemOpen, "dword")
	GUICtrlSetData($SicknessLabel, "Sickness: " & $Sickness)

	$HotkeyLabel = GUICtrlCreateLabel("Heal Hotkey: " & $HealHotkey & "   ExitProgramHotkey: " & $ExitHotkey, 20, 270, 350, 20)
EndFunc   ;==>GUIReadMemory

Func TimeToHeal()
	$HP = _MemoryRead($HPAddress, $MemOpen, "dword")
	$RealHP = $HP / 65536
	$MaxHP = _MemoryRead($MaxHPAddress, $MemOpen, "dword")
	$Chat = _MemoryRead($ChattOpenAddress, $MemOpen, "dword")
	$Sickness = _MemoryRead($SicknessAddress, $MemOpen, "dword")

	If $Sickness = (1 Or 2 Or 65 Or 66 Or 98 Or 8193 Or 8257 Or 16449) Then
		If $elapsedTime >= $HealDelay And $Chat = 0 Then ControlSend("Project Rogue", "", "", "{3}")
		ConsoleWrite("Healing Triggered" & @CRLF)
	ElseIf $RealHP < ($MaxHP * 0.95) Then
		If $elapsedTime >= $HealDelay Then
			ControlSend("Project Rogue", "", "", "{2}")
			$currentTime = TimerInit()
			ConsoleWrite("Healing with Key 2" & @CRLF)
		EndIf
	EndIf
EndFunc   ;==>TimeToHeal

Func AttackModeReader()
	; Read the Attack Mode value
	$AttackMode = _MemoryRead($AttackModeAddress, $MemOpen, "dword")

	;	ConsoleWrite ($Type & @CRLF)

	If $AttackMode = 0 Then
		GUICtrlSetData($AttackModeLabel, "Attack Mode: Safe")
	ElseIf $AttackMode = 1 Then
		GUICtrlSetData($AttackModeLabel, "Attack Mode: Attack")
		If $Type = 0 Then
			ConsoleWrite("Type: Player" & @CRLF)

		ElseIf $Type = 65535 Then
;~ 			ConsoleWrite("Type: " & $Type & @CRLF)
			If $Chat = 0 Then
				If $elapsedTime >= $TargetDelay Then

					ControlSend("Project Rogue", "", "", "{TAB}")

;~ 					ConsoleWrite("Target used at " & @HOUR & ":" & @MIN & ":" & @SEC & @CRLF)
					$currentTime = TimerInit() ;timer
				EndIf
			Else
				If $elapsedTime >= $TargetDelay Then
					ConsoleWrite("[Debug] chat open" & @CRLF)

					$currentTime = TimerInit() ;timer
				EndIf
			EndIf
		ElseIf $Type = 1 Then
;~ 			ConsoleWrite ("Monster targeted" & @CRLF)
		ElseIf $Type = 2 Then
;~ 			ConsoleWrite ("Type: " & $Type  & @CRLF)
		ElseIf $Type = 65535 Then
;~ 			ConsoleWrite ("Type: " & $Type  & @CRLF)
		Else
			ConsoleWrite("Type: " & $Type & @CRLF)
		EndIf
	Else
		GUICtrlSetData($AttackModeLabel, "Attack Mode: No Target")
	EndIf
EndFunc   ;==>AttackModeReader

Func ConnectToBaseAddress()
	$MemOpen = _MemoryOpen($ProcessID)
	$BaseAddress = _EnumProcessModules($MemOpen)
EndFunc   ;==>ConnectToBaseAddress

Func ChangeAddressToBase()
	$TypeAddress = $BaseAddress + $TypeOffset
	$AttackModeAddress = $BaseAddress + $AttackModeOffset
	$PosXAddress = $BaseAddress + $PosXOffset
	$PosYAddress = $BaseAddress + $PosYOffset
	$HPAddress = $BaseAddress + $HPOffset
	$MaxHPAddress = $BaseAddress + $MaxHPOffset
	$ChattOpenAddress = $BaseAddress + $ChattOpenOffset
	$SicknessAddress = $BaseAddress + $SicknessOffset
EndFunc   ;==>ChangeAddressToBase

Func _EnumProcessModules($hProcess)
	Local $hMod = DllStructCreate("ptr")
	Local $moduleSize = DllStructGetSize($hMod)
	Local $aModules = DllCall("psapi.dll", "int", "EnumProcessModulesEx", "ptr", $hProcess, "ptr", DllStructGetPtr($hMod), "dword", $moduleSize, "dword*", 0, "dword", 0x03)

	If IsArray($aModules) And $aModules[0] <> 0 Then Return DllStructGetData($hMod, 1)
	Return 0
EndFunc   ;==>_EnumProcessModules

Func Hotkeyshit()
	$HealerStatus = Not $HealerStatus
	GUICtrlSetData($HealerLabel, "Healer: " & ($HealerStatus ? "On" : "Off"))
	Sleep(300)
EndFunc   ;==>Hotkeyshit

Func KilledWithFire()
	If $Debug Then ConsoleWrite("Killed with fire" & @CRLF)
	Exit
EndFunc   ;==>KilledWithFire

Func TrashHeap()
	Local $endX = 350, $endY = 350
	ConsoleWrite("CHUCKLEFUCKER" & @CRLF)
	MouseClickDrag("left", $aMousePos[0], $aMousePos[1], $endX, $endY, 2)
EndFunc   ;==>TrashHeap
