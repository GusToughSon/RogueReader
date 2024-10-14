#include "NomadMemory.au3"
#include <GUIConstantsEx.au3>
#include <Misc.au3>

; Define the game process and memory offsets
$ProcessName = "Project Rogue Client.exe"
$TypeOffset = 0xBEEA34 ; Memory offset for Type
$AttackModeOffset = 0xAC0D60 ; Memory offset for Attack Mode
$PosXOffset = 0xBF1C6C ; Memory offset for Pos X
$PosYOffset = 0xBF1C64 ; Memory offset for Pos Y
$HPOffset = 0x9BE988 ; Memory offset for HP
$MaxHPOffset = 0x9BE98C ; Memory offset for MaxHP

; Create the GUI with the title "RogueReader" and position it at X=15, Y=15
$Gui = GUICreate("RogueReader", 400, 400, 15, 15) ; Width = 400, Height = 400, X = 15, Y = 15
$TypeLabel = GUICtrlCreateLabel("Type: N/A", 20, 30, 250, 20)
$AttackModeLabel = GUICtrlCreateLabel("Attack Mode: N/A", 20, 60, 250, 20)
$PosXLabel = GUICtrlCreateLabel("Pos X: N/A", 20, 90, 250, 20)
$PosYLabel = GUICtrlCreateLabel("Pos Y: N/A", 20, 120, 250, 20)
$HPLabel = GUICtrlCreateLabel("HP: N/A", 20, 150, 250, 20)
$HP2Label = GUICtrlCreateLabel("HP2: N/A", 20, 180, 250, 20)
$MaxHPLabel = GUICtrlCreateLabel("MaxHP: N/A", 20, 210, 250, 20)
$HealerLabel = GUICtrlCreateLabel("Healer: OFF", 20, 240, 250, 20)
$HotkeyLabel = GUICtrlCreateLabel("Hotkey: `", 20, 270, 250, 20)
$KillButton = GUICtrlCreateButton("Kill Rogue", 20, 300, 100, 30)
$ExitButton = GUICtrlCreateButton("Exit", 150, 300, 100, 30)
GUISetState(@SW_SHOW)

; Healer toggle variable
Global $HealerStatus = False

; Get the process ID
$ProcessID = ProcessExists($ProcessName)
If $ProcessID Then
    ; Open the process memory
    $MemOpen = _MemoryOpen($ProcessID)

    ; Get the base address of the module using EnumProcessModules
    $BaseAddress = _EnumProcessModules($MemOpen)
    If $BaseAddress = 0 Then
        MsgBox(0, "Error", "Failed to get base address")
        Exit
    EndIf

    ; Calculate the target addresses by adding the offsets to the base address
    $TypeAddress = $BaseAddress + $TypeOffset
    $AttackModeAddress = $BaseAddress + $AttackModeOffset
    $PosXAddress = $BaseAddress + $PosXOffset
    $PosYAddress = $BaseAddress + $PosYOffset
    $HPAddress = $BaseAddress + $HPOffset
    $MaxHPAddress = $BaseAddress + $MaxHPOffset

    ; Main loop for the GUI and memory reading
    While 1
        $msg = GUIGetMsg()

        ; Check if the hotkey ` is pressed to toggle the Healer status
        If _IsPressed("C0") Then ; C0 is the virtual key code for the backtick (`) key
            $HealerStatus = Not $HealerStatus
            If $HealerStatus Then
                GUICtrlSetData($HealerLabel, "Healer: ON")
            Else
                GUICtrlSetData($HealerLabel, "Healer: OFF")
            EndIf
            Sleep(300) ; Prevent rapid toggling
        EndIf

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

        ; Read the Type value
        $Type = _MemoryRead($TypeAddress, $MemOpen, "dword")
        If $Type = 0 Then
            GUICtrlSetData($TypeLabel, "Type: Player (" & $Type & ")")
        ElseIf $Type = 1 Then
            GUICtrlSetData($TypeLabel, "Type: Monster (" & $Type & ")")
        ElseIf $Type = 2 Then
            GUICtrlSetData($TypeLabel, "Type: NPC (" & $Type & ")")
        Else
            GUICtrlSetData($TypeLabel, "Type: No Target (" & $Type & ")")
        EndIf

        ; Read the Attack Mode value
        $AttackMode = _MemoryRead($AttackModeAddress, $MemOpen, "dword")
        If $AttackMode = 0 Then
            GUICtrlSetData($AttackModeLabel, "Attack Mode: Safe")
        ElseIf $AttackMode = 1 Then
            GUICtrlSetData($AttackModeLabel, "Attack Mode: Attack")
        Else
            GUICtrlSetData($AttackModeLabel, "Attack Mode: No Target")
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
        GUICtrlSetData($HP2Label, "HP2: " & $HP2)

        ; Read the MaxHP value
        $MaxHP = _MemoryRead($MaxHPAddress, $MemOpen, "dword")
        GUICtrlSetData($MaxHPLabel, "MaxHP: " & $MaxHP)

        ; Refresh every 100 ms
        Sleep(100)
    WEnd

Else
    MsgBox(0, "Error", "Project Rogue Client.exe not found.")
EndIf

; Clean up GUI on exit
GUIDelete($Gui)

; Function to get the base address using EnumProcessModules
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
