#include "NomadMemory.au3"

Global $TypeOffset = 0xBEEA34
Global $AttackModeOffset = 0xAC0D60
Global $PosXOffset = 0xBF1C58
Global $PosYOffset = 0xBF1C50
Global $HPOffset = 0x9BE988
Global $MaxHPOffset = 0x9BE98C
Global $HealerStatus, $ThresholdSlider

Func OpenMemoryProcess($ProcessID)
    If $ProcessID Then
        Return _MemoryOpen($ProcessID)
    Else
        Return 0
    EndIf
EndFunc

Func GetBaseAddress($hProcess)
    Local $hMod = DllStructCreate("ptr") ; Create a structure for a pointer (64-bit)
    Local $moduleSize = DllStructGetSize($hMod)

    ; Call EnumProcessModules to list modules
    Local $aModules = DllCall("psapi.dll", "int", "EnumProcessModulesEx", "ptr", $hProcess, "ptr", DllStructGetPtr($hMod), "dword", $moduleSize, "dword*", 0, "dword", 0x03)

    If @error Or $aModules[0] = 0 Then
        Return 0
    EndIf

    ; Retrieve the base address from the module
    $BaseAddress = DllStructGetData($hMod, 1)
    Return $BaseAddress
EndFunc

Func ProcessLogic($MemOpen, $pottimer, $BaseAddress)
    ; Ensure $BaseAddress has been properly set
    If $BaseAddress = 0 Then
        Return
    EndIf

    ; Read memory and process game logic
    $Type = _MemoryRead($BaseAddress + $TypeOffset, $MemOpen, "dword")
    $AttackMode = _MemoryRead($BaseAddress + $AttackModeOffset, $MemOpen, "dword")
    $PosX = _MemoryRead($BaseAddress + $PosXOffset, $MemOpen, "dword")
    $PosY = _MemoryRead($BaseAddress + $PosYOffset, $MemOpen, "dword")
    $HP = _MemoryRead($BaseAddress + $HPOffset, $MemOpen, "dword")
    $MaxHP = _MemoryRead($BaseAddress + $MaxHPOffset, $MemOpen, "dword")

    ; Update GUI with the new data (using GUIHandler functions)
    UpdateGUI($Type, $AttackMode, $PosX, $PosY, $HP, $MaxHP)

    ; Handle healer logic
    If $HealerStatus And ($HP / 65536) <= (GUICtrlRead($ThresholdSlider) / 100 * $MaxHP) Then
        ConsoleWrite("Healer is ON, pressing 2" & @CRLF)
        Send("2")
        Sleep($pottimer)
    EndIf
EndFunc
