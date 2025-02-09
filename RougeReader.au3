#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=RogueReader.ico
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_Res_Description=Trainer for Project Rogue
#AutoIt3Wrapper_Res_Fileversion=2.0.0.5
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_ProductName=Rogue Reader
#AutoIt3Wrapper_Res_CompanyName=Macro Is Fun .LLC
#AutoIt3Wrapper_Res_LegalCopyright=Use only for authorized security testing. Unauthorized use is illegal. No liability for misuse. © MacroIsFun.LLc 2024
#AutoIt3Wrapper_Res_LegalTradeMarks=Macro Is Fun .LLC
#AutoIt3Wrapper_Res_Language=1033
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

; --- Removed: #include "NomadMemory.au3"
#include <GUIConstantsEx.au3>
#include <File.au3>
#include <JSON.au3>
#include <Misc.au3>

; --- ADDED for WinAPI-based memory approach:
#include <WinAPI.au3>
#include <Process.au3>

Opt("MouseCoordMode", 2)

Global 			$version = FileGetVersion(@ScriptFullPath)
Global Const 	$LOCATION_FILE = @ScriptDir & "\LocationLog.cfg"
Global Const 	$configPath = @ScriptDir & "\Config.json"

ConsoleWrite("Script Version: " & $version & @CRLF)

; --- Load Config Settings ---
Global $HealHotkey = "{`}" ; Default Heal Hotkey
Global $CureHotkey = "{-}" ; Default Cure Hotkey
Global $TargetHotkey = "{]}" ; Default Target Hotkey
Global $ExitHotkey = "{/}"  ; Default Exit Hotkey
LoadConfig()

; --- Set Hotkeys from Config ---
HotKeySet($HealHotkey, "Hotkeyshit")
HotKeySet($CureHotkey, "CureKeyShit")
HotKeySet($TargetHotkey, "TargetKeyShit")
HotKeySet($ExitHotkey, "KilledWithFire")
ConsoleWrite("Heal: " & $HealHotkey & @CRLF)
ConsoleWrite("Cure: " & $CureHotkey & @CRLF)
ConsoleWrite("Target: " & $TargetHotkey & @CRLF)
ConsoleWrite("Exit: " & $ExitHotkey & @CRLF)

Global $Debug = False

; Define the game process and memory offsets
Global $ProcessName 		= "Project Rogue Client.exe"
Global $WindowName 			= "Project Rogue"
Global $TypeOffset 			= 0xBF0B98 ;x
Global $AttackModeOffset 	= 0xAACCC0 ;x
Global $PosXOffset 			= 0xBF3D28 ;Project Rogue Client.exe+BF3D28 #2 Project Rogue Client.exe+BF3D3C
Global $PosYOffset 			= 0xBF3D20 ;Project Rogue Client.exe+BF3D20 #2 Project Rogue Client.exe+BF3D34
Global $HPOffset 			= 0xAB5C30 ;x
Global $MaxHPOffset 		= 0xAB5C34 ;Project Rogue Client.exe+AB5C34
Global $ChattOpenOffset 	= 0x9B7A18 ;x
Global $SicknessOffset 		= 0xAB5E10

Global $Running 			= True ;Does it loop;
Global $HealerStatus 		= 0
Global $CureStatus 			= 0
Global $TargetStatus 		= 0

Global $hProcess 			= 0   ; Our WinAPI handle to the process
Global $BaseAddress			= 0 ; Base address of the module


Global $TypeAddress, $AttackModeAddress, $PosXAddress, $PosYAddress
Global $HPAddress, $MaxHPAddress, $ChattOpenAddress, $SicknessAddress
Global $Type, $Chat, $Sickness
Global $SicknessDescription = GetSicknessDescription(0)

; This array is used in CureMe and TimeToHeal checks
Global $sicknessArray = [1, 2, 65, 66, 67, 68, 69, 72, 73, 81, 97, 98, 99, 513, 514, 515, 577, 8193, 8194, 8195, 8257, 8258, 8705, 8706, 8707, 8708, 8709, 8712, 8713, 8721, 8737, 8769, 8770, 16385, 16386, 16449, 16450, 16451, 16452, 16897, 16898, 24577, 24578, 24579, 24581, 24582, 24583, 24585, 24609, 24641, 24642, 24643, 24645, 24646, 24647, 24649, 25089, 25090, 25091, 25093, 25094, 25095, 25097, 25121, 33283, 33284, 33285, 33286, 33287, 33288, 33289, 33291, 33293, 33294, 33295, 33793, 41985, 41986, 41987, 41988, 41989, 41990, 41991, 41993, 41995]

Global $currentTime 		= TimerInit(), $TargetDelay = 400, $HealDelay = 1700
Global $aMousePos 			= MouseGetPos()

; Create the GUI
Global $Gui 				= GUICreate("RougeReader " & "Version - " & $version, 400, 400, 15, 15)
Global $TypeLabel			= GUICtrlCreateLabel("Type: N/A", 20, 30, 250, 20)
Global $AttackModeLabel 	= GUICtrlCreateLabel("Attack Mode: N/A", 20, 60, 250, 20)
Global $PosXLabel 			= GUICtrlCreateLabel("Pos X: N/A", 20, 90, 250, 20)
Global $PosYLabel 			= GUICtrlCreateLabel("Pos Y: N/A", 20, 120, 250, 20)
Global $HPLabel 			= GUICtrlCreateLabel("HP: N/A", 20, 150, 250, 20)
Global $ChatLabel 			= GUICtrlCreateLabel("Chat: N/A", 120, 150, 250, 20)
Global $HP2Label 			= GUICtrlCreateLabel("RealHp: N/A", 20, 180, 250, 20)
Global $SicknessLabel 		= GUICtrlCreateLabel("Sickness: N/A", 120, 180, 250, 20)
Global $MaxHPLabel 			= GUICtrlCreateLabel("MaxHP: N/A", 20, 210, 250, 20)
Global $TargetLabel 		= GUICtrlCreateLabel("Target: Off", 120, 210, 250, 20)
Global $HealerLabel 		= GUICtrlCreateLabel("Healer: Off", 20, 240, 250, 20)
Global $CureLabel 			= GUICtrlCreateLabel("Cure: Off", 120, 240, 250, 20)
Global $HotkeyLabel 		= GUICtrlCreateLabel("Set hotkeys in the config file", 20, 270, 350, 20)
Global $KillButton 			= GUICtrlCreateButton("Kill Rogue", 20, 300, 100, 30)
Global $ExitButton 			= GUICtrlCreateButton("Exit", 150, 300, 100, 30)

GUISetState(@SW_SHOW)


; ------------------------------------------------------------------------------
;                                   MAIN LOOP
; ------------------------------------------------------------------------------
While 1
    Global $ProcessID = ProcessExists($ProcessName)

    If $ProcessID Then
        ConnectToBaseAddress()

        If $BaseAddress = 0 Or $hProcess = 0 Then
            Sleep(1000)
        Else
            ChangeAddressToBase()
            While $Running And ProcessExists($ProcessID) ; Keep running while process exists
                Local $elapsedTime = TimerDiff($currentTime)
                Local $msg = GUIGetMsg()

                If $msg = $ExitButton Or $msg = $GUI_EVENT_CLOSE Then
                    _WinAPI_CloseHandle($hProcess)
                    GUIDelete($Gui)
                    Exit
                EndIf

                If $msg = $KillButton Then
                    ProcessClose($ProcessID)
                    ExitLoop
                EndIf

				If $Chat = 0 then ;make sure chat is closed to send heals/target
					If $CureStatus = 1 Then
						CureMe()
					EndIf
					If $TargetStatus = 1 Then
						AttackModeReader()
					EndIf
					If $HealerStatus = 1 Then
						TimeToHeal()
					EndIf
				EndIf


                GUIReadMemory()
                Sleep(100)

                ; Check if game is still running, if not, exit the inner loop to reconnect
                If Not ProcessExists($ProcessID) Then
                    ConsoleWrite("[Info] Game closed, waiting to reconnect..." & @CRLF)
                    ExitLoop
                EndIf
            WEnd
        EndIf
    Else
        ConsoleWrite("[Info] Game not found, waiting..." & @CRLF)

        ; Keep checking every 2 seconds until game is reopened
        While Not ProcessExists($ProcessName)
            Sleep(2000)
        WEnd

        ConsoleWrite("[Info] Game detected, reconnecting..." & @CRLF)
    EndIf
WEnd

; Cleanup
GUIDelete($Gui)
_WinAPI_CloseHandle($hProcess)
Exit

; ------------------------------------------------------------------------------
;                                LOAD CONFIG
; ------------------------------------------------------------------------------
Func LoadConfig() ;hotkey config load;
	; Default hotkey settings
	Local $defaultHealHotkey 	= 	"{1}"
	Local $defaultCureHotkey 	=	"{2}"
	Local $defaultTargetHotkey	= 	"{3}"
	Local $defaultExitHotkey 	= 	"{4}"
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
; ------------------------------------------------------------------------------
;                       READ AND UPDATE GUI FROM MEMORY
; ------------------------------------------------------------------------------
Func GUIReadMemory()
	If $hProcess = 0 Then Return

	; Read Type
	$Type = _ReadMemory($hProcess, $TypeAddress)
	If $Type = 0 Then
		GUICtrlSetData($TypeLabel, "Type: Player")
	ElseIf $Type = 1 Then
		GUICtrlSetData($TypeLabel, "Type: Monster")
	ElseIf $Type = 2 Then
		GUICtrlSetData($TypeLabel, "Type: NPC")
	ElseIf $Type = 65535 Then
		GUICtrlSetData($TypeLabel, "Type: No Target")
	Else
		GUICtrlSetData($TypeLabel, "Type: Unknown (" & $Type & ")")
	EndIf

	; Attack Mode
	Local $AttackMode = _ReadMemory($hProcess, $AttackModeAddress)
	If $AttackMode = 0 Then
		GUICtrlSetData($AttackModeLabel, "Attack Mode: Safe")
	ElseIf $AttackMode = 1 Then
		GUICtrlSetData($AttackModeLabel, "Attack Mode: Attack")
	Else
		GUICtrlSetData($AttackModeLabel, "Attack Mode: No Target")
	EndIf

	; Position
	Local $PosX = _ReadMemory($hProcess, $PosXAddress)
	Local $PosY = _ReadMemory($hProcess, $PosYAddress)
	GUICtrlSetData($PosXLabel, "Pos X: " & $PosX)
	GUICtrlSetData($PosYLabel, "Pos Y: " & $PosY)

	; HP
	Local $HP = _ReadMemory($hProcess, $HPAddress)
	GUICtrlSetData($HPLabel, "HP: " & $HP)
	GUICtrlSetData($HP2Label, "RealHp: " & $HP / 65536)

	; MaxHP
	Local $MaxHP = _ReadMemory($hProcess, $MaxHPAddress)
	GUICtrlSetData($MaxHPLabel, "MaxHP: " & $MaxHP)

	; Chat
	Local $ChatVal = _ReadMemory($hProcess, $ChattOpenAddress)
	$Chat = $ChatVal
	GUICtrlSetData($ChatLabel, "Chat: " & $ChatVal)

	; Sickness
	Local $SickVal = _ReadMemory($hProcess, $SicknessAddress)
	$Sickness = $SickVal
	$SicknessDescription = GetSicknessDescription($SickVal)
	GUICtrlSetData($SicknessLabel, "Sickness: " & $SicknessDescription)

	Sleep(50)
EndFunc   ;==>GUIReadMemory

; ------------------------------------------------------------------------------
;                                  CURE FUNCTION
; ------------------------------------------------------------------------------
Func CureMe()
	If $Chat = 0 Then
		If $CureStatus = 1 Then
			If _ArraySearch($sicknessArray, $Sickness) <> -1 Then
				Local $elapsedTime = TimerDiff($currentTime)
				If $elapsedTime >= $HealDelay And $Chat = 0 Then
					ControlSend("Project Rogue", "", "", "{3}")
					ConsoleWrite("[Heal] Healing triggered for sickness condition." & @CRLF)
					; $currentTime = TimerInit() ; Optionally reset the timer
					Return "Healing triggered due to sickness condition"
				EndIf
			EndIf
		EndIf
	EndIf

EndFunc   ;==>CureMe

; ------------------------------------------------------------------------------
;                                   HEALER
; ------------------------------------------------------------------------------
Func TimeToHeal()
	; Re-read HP, MaxHP, Chat, Sickness each time
	Local $HP = _ReadMemory($hProcess, $HPAddress)
	Local $RealHP = $HP / 65536
	Local $MaxHP = _ReadMemory($hProcess, $MaxHPAddress)
	Local $ChatVal = _ReadMemory($hProcess, $ChattOpenAddress)
	Local $SickVal = _ReadMemory($hProcess, $SicknessAddress)

	Local $elapsedTime = TimerDiff($currentTime)

	; If you want special logic for sickness, do it here
	if $chat = 0 then
	If _ArraySearch($sicknessArray, $SickVal) <> -1 Then
		; e.g., ControlSend for cure or something else
	ElseIf $RealHP < ($MaxHP * 0.95) Then
		If $elapsedTime >= $HealDelay Then
			ControlSend("Project Rogue", "", "", "{2}")
			ConsoleWrite("[Heal] Healing triggered due to low HP." & @CRLF)
			$currentTime = TimerInit()
			Return "Healing triggered due to low HP"
		EndIf
	EndIf

	Return "No healing required at this time"
	EndIf

EndFunc   ;==>TimeToHeal

; ------------------------------------------------------------------------------
;                                  TARGETING
; ------------------------------------------------------------------------------
Func AttackModeReader()
	Local $AttackMode = _ReadMemory($hProcess, $AttackModeAddress)
	If $AttackMode = 0 Then
		GUICtrlSetData($AttackModeLabel, "Attack Mode: Safe")
	ElseIf $AttackMode = 1 Then
		GUICtrlSetData($AttackModeLabel, "Attack Mode: Attack")
		If $Type = 0 Then
			ConsoleWrite("Type: Player" & @CRLF)
		ElseIf $Type = 65535 Then
			Local $elapsedTime = TimerDiff($currentTime)
			If $Chat = 0 Then
				If $elapsedTime >= $TargetDelay Then
					ControlSend("Project Rogue", "", "", "{TAB}")
					$currentTime = TimerInit()
				EndIf
			Else
				If $elapsedTime >= $TargetDelay Then
					ConsoleWrite("[Debug] chat open" & @CRLF)
					$currentTime = TimerInit()
				EndIf
			EndIf
		ElseIf $Type = 1 Then
			; "Monster targeted"
		ElseIf $Type = 2 Then
			; "Type: NPC"
		Else
			ConsoleWrite("Type: " & $Type & @CRLF)
		EndIf
	Else
		GUICtrlSetData($AttackModeLabel, "Attack Mode: No Target")
	EndIf
EndFunc   ;==>AttackModeReader

; ------------------------------------------------------------------------------
;                     CONNECT TO PROCESS & GET BASE ADDRESS
; ------------------------------------------------------------------------------
Func ConnectToBaseAddress()
	; 1) Open handle
	$hProcess = _WinAPI_OpenProcess(0x1F0FFF, False, $ProcessID)
	If $hProcess = 0 Then
		ConsoleWrite("[Error] Failed to open process! Try running as administrator." & @CRLF)
		Return
	EndIf

	; 2) Get base address via EnumProcessModules
	$BaseAddress = _GetModuleBase_EnumModules($hProcess)
	If $BaseAddress = 0 Then
		ConsoleWrite("[Error] Failed to obtain a valid base address!" & @CRLF)
	EndIf
EndFunc   ;==>ConnectToBaseAddress

; ------------------------------------------------------------------------------
;                    UPDATE GLOBAL OFFSETS WITH BASE ADDRESS
; ------------------------------------------------------------------------------
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

; ------------------------------------------------------------------------------
;                     WINAPI-BASED MODULE ENUM & MEM READ
; ------------------------------------------------------------------------------
Func _GetModuleBase_EnumModules($hProcess)
	Local $hPsapi = DllOpen("psapi.dll")
	If $hPsapi = 0 Then Return 0

	Local $tModules = DllStructCreate("ptr[1024]")
	Local $tBytesNeeded = DllStructCreate("dword")

	; Call EnumProcessModules
	Local $aCall = DllCall("psapi.dll", "bool", "EnumProcessModules", _
			"handle", $hProcess, _
			"ptr", DllStructGetPtr($tModules), _
			"dword", DllStructGetSize($tModules), _
			"ptr", DllStructGetPtr($tBytesNeeded))

	If @error Or Not $aCall[0] Then
		DllClose($hPsapi)
		Return 0
	EndIf

	; The first module in the list is typically the main base address
	Local $pBaseAddress = DllStructGetData($tModules, 1, 1)
	DllClose($hPsapi)
	Return $pBaseAddress
EndFunc   ;==>_GetModuleBase_EnumModules

Func _ReadMemory($hProcess, $pAddress)
	If $hProcess = 0 Or $pAddress = 0 Then Return 0
	Local $tBuffer = DllStructCreate("dword") ; read a 32-bit value
	Local $aRead = DllCall("kernel32.dll", "bool", "ReadProcessMemory", _
			"handle", $hProcess, _
			"ptr", $pAddress, _
			"ptr", DllStructGetPtr($tBuffer), _
			"dword", DllStructGetSize($tBuffer), _
			"ptr", 0)
	If @error Or Not $aRead[0] Then
		Return 0
	EndIf
	Return DllStructGetData($tBuffer, 1)
EndFunc   ;==>_ReadMemory

; ------------------------------------------------------------------------------
;                           HOTKEY HANDLERS
; ------------------------------------------------------------------------------
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

; ------------------------------------------------------------------------------
;                         SICKNESS DESCRIPTION SWITCH
; ------------------------------------------------------------------------------
Func GetSicknessDescription($Sick)
	Global $SicknessDescription = "Unknown"
	Switch $Sick
		Case 1
			$SicknessDescription = "Poison1"
		Case 2
			$SicknessDescription = "Disease1"
		Case 4
			$SicknessDescription = "Poison4"
		Case 8
			$SicknessDescription = "Disease5"
		Case 16
			$SicknessDescription = "New Affliction 16"
		Case 32
			$SicknessDescription = "New Affliction 32"
		Case 64
			$SicknessDescription = "Vampirism"
		Case 65
			$SicknessDescription = "Vampirism + Poison1"
		Case 66
			$SicknessDescription = "Vampirism + Disease1"
		Case 67
			$SicknessDescription = "Vampirism + Poison1 + Disease1"
		Case 68
			$SicknessDescription = "Vampirism + Poison4"
		Case 69
			$SicknessDescription = "Vampirism + Poison1 + Poison4"
		Case 72
			$SicknessDescription = "Vampirism + Disease5"
		Case 73
			$SicknessDescription = "Vampirism + Poison1 + Disease5"
		Case 80
			$SicknessDescription = "Vampirism + New Affliction 16"
		Case 81
			$SicknessDescription = "Vampirism + Poison1 + New Affliction 16"
		Case 96
			$SicknessDescription = "Vampirism + New Affliction 32"
		Case 97
			$SicknessDescription = "Vampirism + Poison1 + New Affliction 32"
		Case 98
			$SicknessDescription = "Poison3"
		Case 99
			$SicknessDescription = "Disease23"
		Case 512
			$SicknessDescription = "Swiftness"
		Case 576
			$SicknessDescription = "Swiftness + Vampirism"
		Case 577
			$SicknessDescription = "Swiftness + Vampirism + Poison1"
		Case 8192
			$SicknessDescription = "BloodLust"
		Case 8193
			$SicknessDescription = "BloodLust + Poison1"
		Case 8194
			$SicknessDescription = "BloodLust + Disease1"
		Case 8195
			$SicknessDescription = "BloodLust + Poison1 + Disease1"
		Case 8256
			$SicknessDescription = "BloodLust + Vampirism"
		Case 8257
			$SicknessDescription = "BloodLust + Vampirism + Poison1"
		Case 8258
			$SicknessDescription = "BloodLust + Vampirism + Poison1 + Disease1"
		Case 8704
			$SicknessDescription = "BloodLust + Swiftness"
		Case 8705
			$SicknessDescription = "BloodLust + Swiftness + Poison1"
		Case 8706
			$SicknessDescription = "BloodLust + Swiftness + Disease1"
		Case 8707
			$SicknessDescription = "BloodLust + Swiftness + Poison1 + Disease1"
		Case 8708
			$SicknessDescription = "BloodLust + Swiftness + Poison4"
		Case 8709
			$SicknessDescription = "BloodLust + Swiftness + Poison1 + Poison4"
		Case 8712
			$SicknessDescription = "BloodLust + Swiftness + Disease5"
		Case 8713
			$SicknessDescription = "BloodLust + Swiftness + Poison1 + Disease5"
		Case 8720
			$SicknessDescription = "BloodLust + Swiftness + New Affliction 16"
		Case 8721
			$SicknessDescription = "BloodLust + Swiftness + Poison1 + New Affliction 16"
		Case 8736
			$SicknessDescription = "BloodLust + Swiftness + New Affliction 32"
		Case 8737
			$SicknessDescription = "BloodLust + Swiftness + Poison1 + New Affliction 32"
		Case 8768
			$SicknessDescription = "BloodLust + Swiftness + Vampirism"
		Case 8769
			$SicknessDescription = "BloodLust + Swiftness + Vampirism + Poison1"
		Case 8770
			$SicknessDescription = "BloodLust + Swiftness + Vampirism + Disease1"
		Case 16384
			$SicknessDescription = "Exhausted"
		Case 16385
			$SicknessDescription = "Exhausted + Poison1"
		Case 16386
			$SicknessDescription = "Exhausted + Disease1"
		Case 16448
			$SicknessDescription = "Exhausted + Vampirism"
		Case 16449
			$SicknessDescription = "Exhausted + Vampirism + Poison1"
		Case 16450
			$SicknessDescription = "Exhausted + Disease1"
		Case 16451
			$SicknessDescription = "Exhausted + Poison1 + Disease1"
		Case 16452
			$SicknessDescription = "Exhausted + Poison4 + Disease1 + Vampirism"
		Case 16896
			$SicknessDescription = "Swiftness + Exhausted"
		Case 16897
			$SicknessDescription = "Swiftness + Exhausted + Poison1"
		Case 16898
			$SicknessDescription = "Swiftness + Exhausted + Disease1"
		Case 16929
			$SicknessDescription = "Swiftness + Exhausted + Vampirism + Poison1"
		Case 24576
			$SicknessDescription = "BloodLust + Exhausted"
		Case 24577
			$SicknessDescription = "BloodLust + Exhausted + Poison1"
		Case 24578
			$SicknessDescription = "BloodLust + Exhausted + Disease1"
		Case 24579
			$SicknessDescription = "BloodLust + Exhausted + Poison1 + Disease1"
		Case 24580
			$SicknessDescription = "BloodLust + Exhausted + Poison4"
		Case 24581
			$SicknessDescription = "BloodLust + Exhausted + Poison1 + Poison4"
		Case 24582
			$SicknessDescription = "BloodLust + Exhausted + Disease5"
		Case 24583
			$SicknessDescription = "BloodLust + Exhausted + Poison1 + Disease5"
		Case 24584
			$SicknessDescription = "BloodLust + Exhausted + New Affliction 16"
		Case 24585
			$SicknessDescription = "BloodLust + Exhausted + Poison1 + New Affliction 16"
		Case 24608
			$SicknessDescription = "BloodLust + Exhausted + New Affliction 32"
		Case 24609
			$SicknessDescription = "BloodLust + Exhausted + Poison1 + New Affliction 32"
		Case 24640
			$SicknessDescription = "BloodLust + Exhausted + Vampirism"
		Case 24641
			$SicknessDescription = "BloodLust + Exhausted + Vampirism + Poison1"
		Case 24642
			$SicknessDescription = "BloodLust + Exhausted + Vampirism + Disease1"
		Case 24643
			$SicknessDescription = "BloodLust + Exhausted + Vampirism + Poison1 + Disease1"
		Case 24644
			$SicknessDescription = "BloodLust + Exhausted + Vampirism + Poison4"
		Case 24645
			$SicknessDescription = "BloodLust + Exhausted + Vampirism + Poison1 + Poison4"
		Case 24646
			$SicknessDescription = "BloodLust + Exhausted + Vampirism + Disease5"
		Case 24647
			$SicknessDescription = "BloodLust + Exhausted + Vampirism + Poison1 + Disease5"
		Case 24648
			$SicknessDescription = "BloodLust + Exhausted + Vampirism + New Affliction 16"
		Case 24649
			$SicknessDescription = "BloodLust + Exhausted + Vampirism + Poison1 + New Affliction 16"
		Case 24672
			$SicknessDescription = "BloodLust + Exhausted + Vampirism + New Affliction 32"
		Case 24673
			$SicknessDescription = "BloodLust + Exhausted + Vampirism + Poison1 + New Affliction 32"
		Case 25088
			$SicknessDescription = "BloodLust + Exhausted + Swiftness"
		Case 25089
			$SicknessDescription = "BloodLust + Exhausted + Swiftness + Poison1"
		Case 25090
			$SicknessDescription = "BloodLust + Exhausted + Swiftness + Disease1"
		Case 25091
			$SicknessDescription = "BloodLust + Exhausted + Swiftness + Poison1 + Disease1"
		Case 25092
			$SicknessDescription = "BloodLust + Exhausted + Swiftness + Poison4"
		Case 25093
			$SicknessDescription = "BloodLust + Exhausted + Swiftness + Poison1 + Poison4"
		Case 25094
			$SicknessDescription = "BloodLust + Exhausted + Swiftness + Disease5"
		Case 25095
			$SicknessDescription = "BloodLust + Exhausted + Swiftness + Poison1 + Disease5"
		Case 25096
			$SicknessDescription = "BloodLust + Exhausted + Swiftness + New Affliction 16"
		Case 25097
			$SicknessDescription = "BloodLust + Exhausted + Swiftness + Poison1 + New Affliction 16"
		Case 25120
			$SicknessDescription = "BloodLust + Exhausted + Swiftness + New Affliction 32"
		Case 25121
			$SicknessDescription = "BloodLust + Exhausted + Swiftness + Poison1 + New Affliction 32"
		Case 33280
			$SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism"
		Case 33283
			$SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Poison1"
		Case 33284
			$SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Disease1"
		Case 33285
			$SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Poison1 + Disease1"
		Case 33286
			$SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Poison4"
		Case 33287
			$SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Poison1 + Poison4"
		Case 33288
			$SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Disease5"
		Case 33289
			$SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Poison1 + Disease5"
		Case 33290
			$SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + New Affliction 16"
		Case 33291
			$SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Poison1 + New Affliction 16"
		Case 33292
			$SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + New Affliction 32"
		Case 33293
			$SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Poison1 + New Affliction 32"
		Case 33294
			$SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Poison3"
		Case 33295
			$SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Disease23"
		Case 33792
			$SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Swiftness"
		Case 33793
			$SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Swiftness + Poison1"
		Case 41984
			$SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Desperation"
		Case 41985
			$SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Desperation + Poison1"
		Case 41986
			$SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Desperation + Disease1"
		Case 41987
			$SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Desperation + Poison1 + Disease1"
		Case 41988
			$SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Desperation + Poison4"
		Case 41989
			$SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Desperation + Poison1 + Poison4"
		Case 41990
			$SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Desperation + Disease5"
		Case 41991
			$SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Desperation + Poison1 + Disease5"
		Case 41992
			$SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Desperation + New Affliction 16"
		Case 41993
			$SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Desperation + Poison1 + New Affliction 16"
		Case 41994
			$SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Desperation + New Affliction 32"
		Case 41995
			$SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Desperation + Poison1 + New Affliction 32"
		Case Else
			$SicknessDescription = $Sickness
	EndSwitch
	Return $SicknessDescription
EndFunc   ;==>GetSicknessDescription

Func TrashHeap()
	; Remove Function;
EndFunc   ;==>TrashHeap
