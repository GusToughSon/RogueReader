#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=RogueReader.ico
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_Res_Description=Trainer for Project Rogue
#AutoIt3Wrapper_Res_Fileversion=0.0.0.29
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_ProductName=Rogue Reader
#AutoIt3Wrapper_Res_CompanyName=Macro Is Fun .LLC
#AutoIt3Wrapper_Res_LegalCopyright=Use only for authorized security testing. Unauthorized use is illegal. No liability for misuse. © MacroIsFun.LLc 2024
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
Global $CureHotkey = "{-}" ; Default Cure Hotkey
Global $TargetHotkey = "{]}" ; Default Target Hotkey
Global $ExitHotkey = "{/}" ; Default Exit Hotkey
LoadConfig()

; --- Set Hotkeys from Config ---
HotKeySet($HealHotkey, "Hotkeyshit")
HotKeySet($CureHotkey, "CureKeyShit")
HotKeySet($TargetHotkey, "TargetKeyShit")
HotKeySet($ExitHotkey, "KilledWithFire")
;~ HotKeySet("{4}", "TrashHeap")
ConsoleWrite("Heal: " & $HealHotkey)
ConsoleWrite("Cure: " & $CureHotkey)
ConsoleWrite("Target: " & $TargetHotkey)
ConsoleWrite("Exit: " & $ExitHotkey)
$Debug = False

; Define the game process and memory offsets
$ProcessName = "Project Rogue Client.exe"
$WindowName = "Project Rogue"
$TypeOffset = 0xBEFB04
$AttackModeOffset = 0xAC1D70
$PosXOffset = 0xBF2C70
$PosYOffset = 0xBF2C8C
$HPOffset = 0x9BF988
$MaxHPOffset = 0x9BF98C
$ChattOpenOffset = 0x9B6998
$SicknessOffset = 0x9BFB68

Global $Running = True
Global $AttackModeAddress, $TypeAddress, $PosXAddress, $PosYAddress, $HPAddress, $MaxHPAddress, $ChattOpenAddress, $SicknessAddress, $MemOpen
Global $BaseAddress, $Type, $Chat, $Sickness

Global $sicknessArray = [1, 2, 65, 66, 98, 8193, 8257, 16449] ;This is the Cure Codes;

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
$TargetLabel = GUICtrlCreateLabel("Target: Off", 120, 210, 250, 20)
$HealerLabel = GUICtrlCreateLabel("Healer: Off", 20, 240, 250, 20)
$CureLabel = GUICtrlCreateLabel("Cure: Off", 120, 240, 250, 20)
$HotkeyLabel = GUICtrlCreateLabel("Set hotkeys in the config file", 20, 270, 350, 20)
$KillButton = GUICtrlCreateButton("Kill Rogue", 20, 300, 100, 30)
$ExitButton = GUICtrlCreateButton("Exit", 150, 300, 100, 30)
Global $SicknessDescription = GetSicknessDescription($Sickness)
GUISetState(@SW_SHOW)

Global $HealerStatus = 0
Global $CureStatus = 0
Global $TargetStatus = 0
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
				If $CureStatus = 1 Then
					CureMe()
				EndIf

				If $TargetStatus = 1 Then
					AttackModeReader()
				EndIf

				If $HealerStatus = 1 Then
					TimeToHeal()
				EndIf

				GUIReadMemory()

				Sleep(100)
			WEnd
		EndIf
	Else
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
		Sleep(150)
	EndIf






WEnd

; Cleanup
GUIDelete($Gui)


Func LoadConfig()
	; Define the path for the configuration file
	Local $configPath = @ScriptDir & "\Config.json"

	; Default hotkey settings
	Local $defaultHealHotkey = "{1}"
	Local $defaultCureHotkey = "{2}"
	Local $defaultTargetHotkey = "{3}"
	Local $defaultExitHotkey = "{4}"

	; Construct default JSON configuration string
	Local $defaultConfig = StringFormat('{\r\n    "HealHotkey": "%s",\r\n    "CureHotkey": "%s",\r\n    "TargetHotkey": "%s",\r\n    "ExitHotkey": "%s"\r\n}', _
			$defaultHealHotkey, $defaultCureHotkey, $defaultTargetHotkey, $defaultExitHotkey)

	; Check if Config.json exists, create it with defaults if not
	If Not FileExists($configPath) Then
		FileWrite($configPath, $defaultConfig)
		ConsoleWrite("[Info] Config.json created with default hotkeys." & @CRLF)
	Else
		ConsoleWrite("[Info] Config.json found." & @CRLF)
	EndIf

	; Read and validate JSON content
	Local $json = FileRead($configPath)
	If @error Or $json = "" Then
		ConsoleWrite("[Error] Failed to read Config.json or file is empty. Writing default config." & @CRLF)
		FileWrite($configPath, $defaultConfig)
		$json = $defaultConfig ; Load defaults into the script
	EndIf

	; Remove any unwanted characters from the JSON string
	$json = StringReplace($json, "`r", "")
	$json = StringReplace($json, "`n", "")

	; Re-validate JSON structure
	If Not StringRegExp($json, '^\s*\{\s*("([^"]+)"\s*:\s*"[^"]*",?\s*)+\}\s*$', 0) Then
		ConsoleWrite("[Error] Config.json structure invalid. Resetting to defaults." & @CRLF)
		FileWrite($configPath, $defaultConfig)
		$json = $defaultConfig
	EndIf

	; Debug output if needed


	; Initialize settings with default values
	Local $HealHotkey = $defaultHealHotkey
	Local $CureHotkey = $defaultCureHotkey
	Local $TargetHotkey = $defaultTargetHotkey
	Local $ExitHotkey = $defaultExitHotkey

	; Extract and assign each hotkey from JSON
	Local $matchHeal = StringRegExp($json, '"HealHotkey"\s*:\s*"\{([^}]*)\}"', 1)
	Local $matchCure = StringRegExp($json, '"CureHotkey"\s*:\s*"\{([^}]*)\}"', 1)
	Local $matchTarget = StringRegExp($json, '"TargetHotkey"\s*:\s*"\{([^}]*)\}"', 1)
	Local $matchExit = StringRegExp($json, '"ExitHotkey"\s*:\s*"\{([^}]*)\}"', 1)

	; Apply extracted hotkey values or retain defaults if missing
	If IsArray($matchHeal) Then $HealHotkey = "{" & $matchHeal[0] & "}"
	If IsArray($matchCure) Then $CureHotkey = "{" & $matchCure[0] & "}"
	If IsArray($matchTarget) Then $TargetHotkey = "{" & $matchTarget[0] & "}"
	If IsArray($matchExit) Then $ExitHotkey = "{" & $matchExit[0] & "}"

	; Check and update JSON file if any hotkeys are missing
	Local $missingConfig = False
	If Not IsArray($matchHeal) Then
		$json = StringRegExpReplace($json, '}', ',\r\n    "HealHotkey": "' & $HealHotkey & '"\r\n}')
		$missingConfig = True
	EndIf
	If Not IsArray($matchCure) Then
		$json = StringRegExpReplace($json, '}', ',\r\n    "CureHotkey": "' & $CureHotkey & '"\r\n}')
		$missingConfig = True
	EndIf
	If Not IsArray($matchTarget) Then
		$json = StringRegExpReplace($json, '}', ',\r\n    "TargetHotkey": "' & $TargetHotkey & '"\r\n}')
		$missingConfig = True
	EndIf
	If Not IsArray($matchExit) Then
		$json = StringRegExpReplace($json, '}', ',\r\n    "ExitHotkey": "' & $ExitHotkey & '"\r\n}')
		$missingConfig = True
	EndIf

	; Write any changes to the configuration file
	If $missingConfig Then
		FileWrite($configPath, $json)
		ConsoleWrite("[Info] Config.json updated with missing hotkeys." & @CRLF)
	EndIf

	; Assign hotkeys to actions
	HotKeySet($HealHotkey, "Hotkeyshit")
	HotKeySet($CureHotkey, "Curekeyshit")
	HotKeySet($TargetHotkey, "Targetkeyshit")
	HotKeySet($ExitHotkey, "KilledWithFire")

	; Display the final configuration for confirmation
	ConsoleWrite("[Config] HealHotkey set to: " & $HealHotkey & @CRLF)
	ConsoleWrite("[Config] CureHotkey set to: " & $CureHotkey & @CRLF)
	ConsoleWrite("[Config] TargetHotkey set to: " & $TargetHotkey & @CRLF)
	ConsoleWrite("[Config] ExitHotkey set to: " & $ExitHotkey & @CRLF)
EndFunc   ;==>LoadConfig



Func GUIReadMemory()
	If Not IsPtr($MemOpen) Then Return

	; Read Type and update in GUI
	$Type = _MemoryRead($TypeAddress, $MemOpen, "dword")
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
	$AttackMode = _MemoryRead($AttackModeAddress, $MemOpen, "dword")
	If $AttackMode = 0 Then
		GUICtrlSetData($AttackModeLabel, "Attack Mode: Safe")
	ElseIf $AttackMode = 1 Then
		GUICtrlSetData($AttackModeLabel, "Attack Mode: Attack")
	Else
		GUICtrlSetData($AttackModeLabel, "Attack Mode: No Target")
	EndIf
	; Read Position
	$PosX = _MemoryRead($PosXAddress, $MemOpen, "dword")
	GUICtrlSetData($PosXLabel, "Pos X: " & $PosX)

	$PosY = _MemoryRead($PosYAddress, $MemOpen, "dword")
	GUICtrlSetData($PosYLabel, "Pos Y: " & $PosY)

	; Read HP and MaxHP
	$HP = _MemoryRead($HPAddress, $MemOpen, "dword")
	GUICtrlSetData($HPLabel, "HP: " & $HP)
	GUICtrlSetData($HP2Label, "RealHp: " & $HP / 65536)

	$MaxHP = _MemoryRead($MaxHPAddress, $MemOpen, "dword")
	GUICtrlSetData($MaxHPLabel, "MaxHP: " & $MaxHP)

	; Read Chat status
	$Chat = _MemoryRead($ChattOpenAddress, $MemOpen, "dword")
	GUICtrlSetData($ChatLabel, "Chat: " & $Chat)

	; Read Sickness and update SicknessDescription in GUI
	$Sickness = _MemoryRead($SicknessAddress, $MemOpen, "dword")
	$SicknessDescription = GetSicknessDescription($Sickness) ; Fetch description based on code
	GUICtrlSetData($SicknessLabel, "Sickness: " & $SicknessDescription)

	Sleep(50)
EndFunc   ;==>GUIReadMemory


Func CureMe()
	If $CureStatus = 1 Then
		If _ArraySearch($sicknessArray, $Sickness) <> -1 Then


			If $elapsedTime >= $HealDelay And $Chat = 0 Then
				ControlSend("Project Rogue", "", "", "{3}")
				ConsoleWrite("[Heal] Healing triggered for sickness condition." & @CRLF)
;~ 			$currentTime = TimerInit() ; Reset timer after healing
				Return "Healing triggered due to sickness condition"
			EndIf
		EndIf
	EndIf

EndFunc   ;==>CureMe

Func TimeToHeal()
	; Initialize variables for health and sickness checks
	$HP = _MemoryRead($HPAddress, $MemOpen, "dword")
	$RealHP = $HP / 65536
	$MaxHP = _MemoryRead($MaxHPAddress, $MemOpen, "dword")
	$Chat = _MemoryRead($ChattOpenAddress, $MemOpen, "dword")
	$Sickness = _MemoryRead($SicknessAddress, $MemOpen, "dword")

	; Define elapsed time for cooldown check
	Local $elapsedTime = TimerDiff($currentTime)

	; Check for sickness and initiate healing if needed
	If _ArraySearch($sicknessArray, $Sickness) <> -1 Then
		; Check if RealHP is below 95% of MaxHP for standard healing
	ElseIf $RealHP < ($MaxHP * 0.95) Then
		If $elapsedTime >= $HealDelay Then
			ControlSend("Project Rogue", "", "", "{2}")
			ConsoleWrite("[Heal] Healing triggered due to low HP." & @CRLF)
			$currentTime = TimerInit() ; Reset timer after healing
			Return "Healing triggered due to low HP"
		EndIf
	EndIf

	; Return status if no healing was needed
	Return "No healing required at this time"
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

Func CureKeyShit()
	$CureStatus = Not $CureStatus
	GUICtrlSetData($CureLabel, "Cure: " & ($CureStatus ? "On" : "Off"))
	Sleep(300)
EndFunc   ;==>CureKeyShit

Func TargetKeyShit()
	$TargetStatus = Not $TargetStatus
	GUICtrlSetData($TargetLabel, "Target: " & ($TargetStatus ? "On" : "Off"))



	Sleep(300)
EndFunc   ;==>TargetKeyShit

Func KilledWithFire()
	If $Debug Then ConsoleWrite("Killed with fire" & @CRLF)
	Exit
EndFunc   ;==>KilledWithFire

Func GetSicknessDescription($code)
	Global $SicknessDescription = "Unknown"
	Switch $code
		Case 1


			$SicknessDescription = "Poison1"
		Case 2
			$SicknessDescription = "Disease1"
		Case 64
			$SicknessDescription = 'Vampirism'
		Case 65
			$SicknessDescription = "Poison2"
		Case 66
			$SicknessDescription = "Disease2"
		Case 98
			$SicknessDescription = "Poison3"
		Case 512
			$SicknessDescription = "Swiftness"
		Case 8193
			$SicknessDescription = 'Poison4'
		Case 8256
			$SicknessDescription = "Vamp + Blood"
		Case 16384
			$SicknessDescription = 'Exhausted'
		Case 16448
			$SicknessDescription = 'Vamp + Exha'
		Case 16896
			$SicknessDescription = "Swif + Exha"
		Case Else
			$SicknessDescription = $Sickness
	EndSwitch
	Return $SicknessDescription
EndFunc   ;==>GetSicknessDescription

Func TrashHeap()
	Local $endX = 350, $endY = 350
	ConsoleWrite("CHUCKLEFUCKER" & @CRLF)
	MouseClickDrag("left", $aMousePos[0], $aMousePos[1], $endX, $endY, 2)
EndFunc   ;==>TrashHeap
