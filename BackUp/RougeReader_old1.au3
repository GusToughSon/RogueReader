#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=RogueReader.ico
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_Res_Description=Trainer for Project Rouge
#AutoIt3Wrapper_Res_Fileversion=.01
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

HotKeySet ("{`}", "Hotkeyshit")
HotKeySet ("{/}", "KilledWithFire")

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
Global $AttackModeAddress, $TypeAddress, $PosXAddress, $PosYAddress, $HPAddress, $MaxHPAddress,$ChattOpenAddress,$SicknessAddress, $MemOpen
;---Target config shit--
Global $currentTime = TimerInit()
Global $TargetDelay = 400






; Create the GUI with the title "RougeReader" and position it at X=15, Y=15
$Gui = GUICreate("RougeReader", 400, 400, 15, 15) ; Width = 400, Height = 400, X = 15, Y = 15
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
;$RealHP < ($MaxHP * 0.95); the code if under 95%
; Healer toggle variable
Global $HealerStatus = False
Global $BaseAddress ,$MemOpen
Global $Type = _MemoryRead($TypeAddress, $MemOpen, "dword")

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
    While 1
		Local $elapsedTime = TimerDiff($currentTime) ; Calculate time elapsed
        $msg = GUIGetMsg()
        ; Exit the script if the Exit button is clicked
        If $msg = $ExitButton Then
            _MemoryClose($MemOpen) ; Close memory handle
            Exit
        EndIf
        ; Kill the Rogue process if the Kill button is clicked
        If $msg = $KillButton Then
            ProcessClose($ProcessID)
            Exit
        EndIf

;-------------------------------------------------------------------------------


		AttackModeReader()

		GUIReadMemory()
        ; Refresh every 100 ms
        Sleep(100)
    WEnd
Else
    MsgBox(0, "Error", "Project Rogue Client.exe not found.")
EndIf

; Clean up GUI on exit
GUIDelete($Gui)

Func AttackModeReader()
	; Read the Attack Mode value
	$AttackMode = _MemoryRead($AttackModeAddress, $MemOpen, "dword")
	$Type = _MemoryRead($TypeAddress, $MemOpen, "dword")
;	ConsoleWrite ($Type & @CRLF)

	If $AttackMode = 0 Then
		GUICtrlSetData($AttackModeLabel, "Attack Mode: Safe")
	ElseIf $AttackMode = 1 Then
		GUICtrlSetData($AttackModeLabel, "Attack Mode: Attack")
		If $Type = 0 Then
;~ 			ConsoleWrite ("Type: " & $Type  & @CRLF)

		Elseif $Type = 65535 Then
			ConsoleWrite ("Type: " & $Type  & @CRLF)
			If $elapsedTime >= $TargetDelay	Then

				ControlSend ("Project Rogue", "", "", "{TAB}")
				$currentTime = TimerInit()
				ConsoleWrite("Target used at " & @HOUR & ":" & @MIN & ":" & @SEC & @CRLF)





			EndIf

		Elseif $Type = 2 Then
;~ 			ConsoleWrite ("Type: " & $Type  & @CRLF)
		Elseif $Type = 65535 Then
;~ 			ConsoleWrite ("Type: " & $Type  & @CRLF)
		Else
			ConsoleWrite ("Type: " & $Type  & @CRLF)
		EndIf
	Else
		GUICtrlSetData($AttackModeLabel, "Attack Mode: No Target")
	EndIf
EndFunc

Func GUIReadMemory()
		; Read the Type value
        If $Type = 0 Then
            GUICtrlSetData($TypeLabel, "Type: Player (" & $Type & ")")
        ElseIf $Type = 1 Then
            GUICtrlSetData($TypeLabel, "Type: Monster (" & $Type & ")")
        ElseIf $Type = 2 Then
            GUICtrlSetData($TypeLabel, "Type: NPC (" & $Type & ")")
        Else
            GUICtrlSetData($TypeLabel, "Type: No Target (" & $Type & ")")
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
EndFunc

Func Hotkeyshit()
If $Debug = true Then
	ConsoleWrite ("" & @CRLF)
EndIf
	$HealerStatus = Not $HealerStatus
	If $HealerStatus Then
		GUICtrlSetData($HealerLabel, "Healer: ON")
		If $Debug = true Then
			ConsoleWrite ("Turned Healer on." & @CRLF)
		EndIf
	Else
		GUICtrlSetData($HealerLabel, "Healer: OFF")
		If $Debug = true Then
			ConsoleWrite ("Turned Healer off." & @CRLF)
		EndIf
	EndIf
		Sleep(300) ; Prevent rapid toggling
EndFunc

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
EndFunc
;connect to the base address
Func ConnectToBaseAddress()
	; Open the process memory
    $MemOpen = _MemoryOpen($ProcessID)

    ; Get the base address of the module using EnumProcessModules
    $BaseAddress = _EnumProcessModules($MemOpen)
EndFunc

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
EndFunc

Func KilledWithFire()
	If $Debug = true Then
		ConsoleWrite ("Killed with fire" & @CRLF)
	EndIf
	Exit
EndFunc