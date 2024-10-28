#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=RogueReader.ico
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_Res_Description=Trainer for Project Rouge
#AutoIt3Wrapper_Res_Fileversion=0.0.0.7
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
ConsoleWrite($version & @CRLF)

HotKeySet("{1}", "Hotkeyshit")
HotKeySet("{/}", "KilledWithFire")
HotKeySet("{4}", "TrashHeap")
$Debug = False
; Define the game process and memory offsets
$ProcessName = "Project Rogue Client.exe"
$WindowName = "Project Rogue"
$TypeOffset = 0xBEFB04 ; Memory offset for Type
$AttackModeOffset = 0xAC1D70 ; Memory offset for Attack Mode
$PosXOffset = 0xBF2C70 ; Memory offset for Pos X
$PosYOffset = 0xBF2C68 ; Memory offset for Pos Y
$HPOffset = 0x9BF988 ; Memory offset for HP
$MaxHPOffset = 0x9BF98C ; Memory offset for MaxHP
$ChattOpenOffset = 0x9B6998 ; memory of chat
$SicknessOffset = 0x9BFB68 ;memory of sickness
Global $Running = True
Global $AttackModeAddress, $TypeAddress, $PosXAddress, $PosYAddress, $HPAddress, $MaxHPAddress, $ChattOpenAddress, $SicknessAddress, $MemOpen
Global $BaseAddress, $MemOpen, $Type, $Chat
;---Target config shit--
Global $currentTime = TimerInit(), $TargetDelay = 400, $HealDelay = 1700
Global $aMousePos = MouseGetPos()
Global $startX = $aMousePos[0], $startY = $aMousePos[1], $endX = 350, $endY = 350

; Create the GUI with the title "RougeReader" and position it at X=15, Y=15
$Gui = GUICreate("RougeReader " & "Version - " & $version, 400, 400, 15, 15) ; Width = 400, Height = 400, X = 15, Y = 15
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
$HotkeyLabel = GUICtrlCreateLabel("Hotkey: `", 20, 270, 250, 20)
$KillButton = GUICtrlCreateButton("Kill Rogue", 20, 300, 100, 30)
$ExitButton = GUICtrlCreateButton("Exit", 150, 300, 100, 30)
GUISetState(@SW_SHOW)

; Healer toggle variable
Global $HealerStatus = 0


; Get the process ID
$ProcessID = ProcessExists($ProcessName)
If $ProcessID Then
	ConnectToBaseAddress()
	If $BaseAddress = 0 Then
		MsgBox(0, "Error", "Failed to get base address")
		Exit
	EndIf
	ChangeAddressToBase()
	;---------Main loop for the GUI and Ability to Exit the GUI---------------------
	While $Running
		Local $elapsedTime = TimerDiff($currentTime) ; Calculate time elapsed
		$msg = GUIGetMsg()
		; Exit the script if the Exit button is clicked
		If $msg = $ExitButton Then
			_MemoryClose($MemOpen) ; Close memory handle
			Exit
		EndIf
		If $msg = $GUI_EVENT_CLOSE Or $msg = $ExitButton Then
			_MemoryClose($MemOpen) ; Close memory handle if needed
			Exit
		EndIf
		If $msg = $GUI_EVENT_Minimize Then
			Exit
		EndIf

		; Kill the Rogue process if the Kill button is clicked
		If $msg = $KillButton Then
			ProcessClose($ProcessID)

		EndIf
		;-------------------------------------------------------------------------------

		AttackModeReader()
		If $HealerStatus = 1 Then
			TimeToHeal()
		EndIf

		GUIReadMemory()

		; Refresh every 100 ms
		Sleep(100)
	WEnd
Else
	MsgBox(0, "Error", "Project Rogue Client.exe not found.")
EndIf

; Clean up GUI on exit
GUIDelete($Gui)
Func TimeToHeal()
	$HP = _MemoryRead($HPAddress, $MemOpen, "dword")
	$RealHP = $HP / 65536
	$MaxHP = _MemoryRead($MaxHPAddress, $MemOpen, "dword")
	$Chat = _MemoryRead($ChattOpenAddress, $MemOpen, "dword")
	$Sickness = _MemoryRead($SicknessAddress, $MemOpen, "dword")
;~ 	ConsoleWrite($Sickness & @CRLF)
	If $Sickness = (1 Or 2 Or 65 Or 66 Or 98 Or 8193 Or 8257 Or 16449) Then
		If $elapsedTime >= $HealDelay Then
			If $Chat = 0 Then
				ControlSend("Project Rogue", "", "", "{3}")

			EndIf
		EndIf
		ConsoleWrite("zzzzzzzz")
	ElseIf $RealHP < ($MaxHP * 0.95) Then
		If $elapsedTime >= $HealDelay Then
			ControlSend("Project Rogue", "", "", "{2}")

			$currentTime = TimerInit()
			ConsoleWrite("yyyyyyyyyyy")
		EndIf

	EndIf    ; the code if under 95%
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

Func GUIReadMemory()
	$Type = _MemoryRead($TypeAddress, $MemOpen, "dword")
	; Read the Type value
	If $Type = 0 Then
		GUICtrlSetData($TypeLabel, "Type: Player")
	ElseIf $Type = 1 Then
		GUICtrlSetData($TypeLabel, "Type: Monster")
	ElseIf $Type = 2 Then
		GUICtrlSetData($TypeLabel, "Type: NPC")
	Else
		GUICtrlSetData($TypeLabel, "Type: No Target ") ;65535
	EndIf
	; Read the Pos X value
	$PosX = _MemoryRead($PosXAddress, $MemOpen, "dword")
	GUICtrlSetData($PosXLabel, "Pos X: " & $PosX)
	; Read the Pos Y value
	$PosY = _MemoryRead($PosYAddress, $MemOpen, "dword")
	GUICtrlSetData($PosYLabel, "Pos Y: " & $PosY)
	; Read the HP value
	$HP = _MemoryRead($HPAddress, $MemOpen, "dword")
	GUICtrlSetData($HPLabel, "HP: " & $HP)
	; Calculate and display HP2 (HP / 65536)
	$HP2 = $HP / 65536
	GUICtrlSetData($HP2Label, "RealHp: " & $HP2)
	; Read the MaxHP value
	$MaxHP = _MemoryRead($MaxHPAddress, $MemOpen, "dword")
	GUICtrlSetData($MaxHPLabel, "MaxHP: " & $MaxHP)
	$Chat = _MemoryRead($ChattOpenAddress, $MemOpen, "dword")
	GUICtrlSetData($ChatLabel, "Chat: " & $Chat)
	$Sickness = _MemoryRead($SicknessAddress, $MemOpen, "dword")
	GUICtrlSetData($SicknessLabel, "Sickness: " & $Sickness)

EndFunc   ;==>GUIReadMemory

Func Hotkeyshit()

	If $HealerStatus = 1 Then
		$HealerStatus = 0
	Else
		$HealerStatus = 1
	EndIf
	Sleep(300)     ; Prevent rapid toggling
EndFunc   ;==>Hotkeyshit

; get the base address
Func _EnumProcessModules($hProcess)
	Local $hMod = DllStructCreate("ptr") ; 64-bit pointer
	Local $moduleSize = DllStructGetSize($hMod)
	; Call EnumProcessModules to list modules
	Local $aModules = DllCall("psapi.dll", "int", "EnumProcessModulesEx", "ptr", $hProcess, "ptr", DllStructGetPtr($hMod), "dword", $moduleSize, "dword*", 0, "dword", 0x03)

	If IsArray($aModules) And $aModules[0] <> 0 Then
		Return DllStructGetData($hMod, 1) ; Return base address
	Else
		Return 0
	EndIf
EndFunc   ;==>_EnumProcessModules
;connect to the base address
Func ConnectToBaseAddress()
	; Open the process memory
	$MemOpen = _MemoryOpen($ProcessID)

	; Get the base address of the module using EnumProcessModules
	$BaseAddress = _EnumProcessModules($MemOpen)
EndFunc   ;==>ConnectToBaseAddress

Func ChangeAddressToBase()
	; Calculate the target addresses by adding the offsets to the base address
	$TypeAddress = $BaseAddress + $TypeOffset
	$AttackModeAddress = $BaseAddress + $AttackModeOffset
	$PosXAddress = $BaseAddress + $PosXOffset
	$PosYAddress = $BaseAddress + $PosYOffset
	$HPAddress = $BaseAddress + $HPOffset
	$MaxHPAddress = $BaseAddress + $MaxHPOffset
	$ChattOpenAddress = $BaseAddress + $ChattOpenOffset
	$SicknessAddress = $BaseAddress + $SicknessOffset
EndFunc   ;==>ChangeAddressToBase

Func KilledWithFire()
	If $Debug = True Then
		ConsoleWrite("Killed with fire" & @CRLF)
	EndIf
	Exit
EndFunc   ;==>KilledWithFire

Func TrashHeap()
	ConsoleWrite("CHUCKLEFUCKER" & @CRLF)
	ControlClick($WindowName, "", "", "left", 2, $startX, $startY)
	Sleep(100) ; Small delay for the click event

	; Optionally, use a loop to send small incremental drags to simulate movement
	For $i = 1 To 10
		; Calculate intermediate coordinates for smooth movement
		Local $intermediateX = $startX + ($endX - $startX) * ($i / 10)
		Local $intermediateY = $startY + ($endY - $startY) * ($i / 10)

		; Send click at each intermediate point
		ControlClick($WindowName, "", "", "left", 1, $intermediateX, $intermediateY)
		Sleep(50) ; Adjust delay for smoother or faster drag
	Next

	; Release the click at the end point
	ControlClick($WindowName, "", "", "left", 1, $endX, $endY)
	Sleep(100)
EndFunc   ;==>TrashHeap
