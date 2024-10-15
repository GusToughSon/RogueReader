#include "NomadMemory.au3"
#include <GUIConstantsEx.au3>
#include <Misc.au3>

Global $pottimer = 2000
$Gui = GUICreate("RogueReader", 450, 500, 15, 15)
$TypeLabel = GUICtrlCreateLabel("Type: N/A", 20, 30, 250, 20)
$AttackModeLabel = GUICtrlCreateLabel("Attack Mode: N/A", 20, 60, 250, 20)
$PosXLabel = GUICtrlCreateLabel("Pos X: N/A", 20, 90, 250, 20)
$PosYLabel = GUICtrlCreateLabel("Pos Y: N/A", 20, 120, 250, 20)
$HPLabel = GUICtrlCreateLabel("HP: N/A", 20, 150, 250, 20)
$HP2Label = GUICtrlCreateLabel("HP2: N/A", 20, 180, 250, 20)
$MaxHPLabel = GUICtrlCreateLabel("MaxHP: N/A", 20, 210, 250, 20)
$HealerLabel = GUICtrlCreateLabel("Healer: OFF", 20, 240, 250, 20)
$HotkeyLabel = GUICtrlCreateLabel("Hotkey: `", 20, 270, 250, 20)
$PotsNote = GUICtrlCreateLabel("Pots go in #2", 20, 300, 250, 20)
$MapLabel = GUICtrlCreateLabel("Map: Off", 20, 340, 250, 20)
$MapButton = GUICtrlCreateButton("Toggle Map", 300, 340, 100, 20)
$KillButton = GUICtrlCreateButton("Kill Rogue", 20, 380, 100, 30)
$ExitButton = GUICtrlCreateButton("Exit", 150, 380, 100, 30)
GUISetState(@SW_SHOW)

Global $HealerStatus = False
Global $MapStatus = False

$ProcessID = ProcessExists("Project Rogue Client.exe")
If $ProcessID Then
    $MemOpen = _MemoryOpen($ProcessID)
    $BaseAddress = _EnumProcessModules($MemOpen)
    If $BaseAddress = 0 Then Exit

    $TypeAddress = $BaseAddress + 0xBEEA34
    $AttackModeAddress = $BaseAddress + 0xAC0D60
    $PosXAddress = $BaseAddress + 0xBF1C6C
    $PosYAddress = $BaseAddress + 0xBF1C64
    $HPAddress = $BaseAddress + 0x9BE988
    $MaxHPAddress = $BaseAddress + 0x9BE98C

    While 1
        $msg = GUIGetMsg()

        If _IsPressed("C0") Then
            $HealerStatus = Not $HealerStatus
            GUICtrlSetData($HealerLabel, "Healer: " & ($HealerStatus ? "ON" : "OFF"))
            Sleep(300)
        EndIf

        If $msg = $MapButton Then
            $MapStatus = Not $MapStatus
            GUICtrlSetData($MapLabel, "Map: " & ($MapStatus ? "Debug" : "Off"))
        EndIf

        If $msg = $ExitButton Then
            _MemoryClose($MemOpen)
            Exit
        EndIf

        If $msg = $KillButton Then
            ProcessClose($ProcessID)
            Exit
        EndIf

        $Type = _MemoryRead($TypeAddress, $MemOpen, "dword")
        Switch $Type
            Case 0
                GUICtrlSetData($TypeLabel, "Type: Player")
            Case 1
                GUICtrlSetData($TypeLabel, "Type: Monster")
            Case 2
                GUICtrlSetData($TypeLabel, "Type: NPC")
            Case Else
                GUICtrlSetData($TypeLabel, "Type: No Target")
        EndSwitch

        $AttackMode = _MemoryRead($AttackModeAddress, $MemOpen, "dword")
        GUICtrlSetData($AttackModeLabel, "Attack Mode: " & ($AttackMode ? "Attack" : "Safe"))

        $PosX = _MemoryRead($PosXAddress, $MemOpen, "dword")
        GUICtrlSetData($PosXLabel, "Pos X: " & $PosX)

        $PosY = _MemoryRead($PosYAddress, $MemOpen, "dword")
        GUICtrlSetData($PosYLabel, "Pos Y: " & $PosY)

        $HP = _MemoryRead($HPAddress, $MemOpen, "dword")
        GUICtrlSetData($HPLabel, "HP: " & $HP)

        $HP2 = $HP / 65536
        GUICtrlSetData($HP2Label, "HP2: " & $HP2)

        $MaxHP = _MemoryRead($MaxHPAddress, $MemOpen, "dword")
        GUICtrlSetData($MaxHPLabel, "MaxHP: " & $MaxHP)

        If $HealerStatus And $HP2 <= (0.95 * $MaxHP) Then
            ControlSend("", "", "", "2")
            Sleep($pottimer)
        EndIf

        Sleep(100)
    WEnd
Else
    MsgBox(0, "Error", "Project Rogue Client.exe not found.")
EndIf

Func _EnumProcessModules($hProcess)
    Local $hMod = DllStructCreate("ptr")
    Local $moduleSize = DllStructGetSize($hMod)
    Local $aModules = DllCall("psapi.dll", "int", "EnumProcessModulesEx", "ptr", $hProcess, "ptr", DllStructGetPtr($hMod), "dword", $moduleSize, "dword*", 0, "dword", 0x03)
    If IsArray($aModules) And $aModules[0] <> 0 Then Return DllStructGetData($hMod, 1)
    Return 0
EndFunc
