#include "NomadMemory.au3"
#include <GUIConstantsEx.au3>

; Define the game process and memory offsets
$ProcessName = "Project Rogue Client.exe"
$TypeOffset = 0xBEEA34 ; Memory offset for Type
$AttackModeOffset = 0xAC0D60 ; Memory offset for Attack Mode
$PosXOffset = 0xBF1C6C ; Memory offset for Pos X
$PosYOffset = 0xBF1C64 ; Memory offset for Pos Y

; Create the GUI with the title "RougeReader" and position it at X=15, Y=15
$Gui = GUICreate("RougeReader", 400, 300, 15, 15) ; Width = 400, Height = 300, X = 15, Y = 15
$TypeLabel = GUICtrlCreateLabel("Type: N/A", 20, 30, 250, 20)
$AttackModeLabel = GUICtrlCreateLabel("Attack Mode: N/A", 20, 60, 250, 20)
$PosXLabel = GUICtrlCreateLabel("Pos X: N/A", 20, 90, 250, 20)
$PosYLabel = GUICtrlCreateLabel("Pos Y: N/A", 20, 120, 250, 20)
$KillButton = GUICtrlCreateButton("Kill Rogue", 20, 160, 100, 30)
$ExitButton = GUICtrlCreateButton("Exit", 150, 160, 100, 30)
GUISetState(@SW_SHOW)

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

    ; Main loop for the GUI and memory reading
    While 1
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
