#include "NomadMemory.au3"
#include <Misc.au3>
#include <WinAPIProc.au3>

Global $ProcessName = "Project Rogue Client.exe", $HealerStatus, $ThresholdSlider  ; Declare the necessary globals

; Memory offsets
Global $TypeOffset = 0xBEEA34
Global $AttackModeOffset = 0xAC0D60
Global $PosXOffset = 0xBF1C58
Global $PosYOffset = 0xBF1C50
Global $HPOffset = 0x9BE988
Global $MaxHPOffset = 0x9BE98C

Func OpenMemoryProcess($ProcessID)
    If $ProcessID Then
        ConsoleWrite("Process ID found: " & $ProcessID & @CRLF)
        Return _MemoryOpen($ProcessID)
    Else
        ConsoleWrite("Process not found: " & $ProcessName & @CRLF)
        Return 0
    EndIf
EndFunc

; Manually enumerate the process modules to get the base address
Func GetBaseAddress($hProcess)
    Local $hMod = DllStructCreate("ptr") ; Create a structure for a pointer (64-bit)
    Local $moduleSize = DllStructGetSize($hMod)

    ; Call EnumProcessModules to list modules
    Local $aModules = DllCall("psapi.dll", "int", "EnumProcessModulesEx", "ptr", $hProcess, "ptr", DllStructGetPtr($hMod), "dword", $moduleSize, "dword*", 0, "dword", 0x03)

    If @error Or $aModules[0] = 0 Then
        ConsoleWrite("Error: Failed to enumerate process modules." & @CRLF)
        Return 0
    EndIf

    ; Retrieve the base address from the module
    $BaseAddress = DllStructGetData($hMod, 1)
    ConsoleWrite("Base address retrieved using EnumProcessModules: " & Hex($BaseAddress) & @CRLF)

    Return $BaseAddress
EndFunc

Func ProcessLogic($MemOpen, $pottimer, $BaseAddress)
    ; Ensure $BaseAddress has been properly set
    If $BaseAddress = 0 Then
        ConsoleWrite("Base address is not set." & @CRLF)
        Return
    EndIf

    ConsoleWrite("Processing memory for game logic..." & @CRLF)

    ; Read memory and process game logic
    $Type = _MemoryRead($BaseAddress + $TypeOffset, $MemOpen, "dword")
    ConsoleWrite("Type Read: " & $Type & @CRLF)

    $AttackMode = _MemoryRead($BaseAddress + $AttackModeOffset, $MemOpen, "dword")
    ConsoleWrite("Attack Mode Read: " & $AttackMode & @CRLF)

    $PosX = _MemoryRead($BaseAddress + $PosXOffset, $MemOpen, "dword")
    ConsoleWrite("Pos X Read: " & $PosX & @CRLF)

    $PosY = _MemoryRead($BaseAddress + $PosYOffset, $MemOpen, "dword")
    ConsoleWrite("Pos Y Read: " & $PosY & @CRLF)

    $HP = _MemoryRead($BaseAddress + $HPOffset, $MemOpen, "dword")
    ConsoleWrite("HP Read: " & $HP & @CRLF)

    $MaxHP = _MemoryRead($BaseAddress + $MaxHPOffset, $MemOpen, "dword")
    ConsoleWrite("Max HP Read: " & $MaxHP & @CRLF)

    ; Update GUI with the new data (using GUIHandler functions)
    UpdateGUI($Type, $AttackMode, $PosX, $PosY, $HP, $MaxHP)

    ; Handle logic for healer and attack mode
    If $HealerStatus And ($HP / 65536) <= (GUICtrlRead($ThresholdSlider) / 100 * $MaxHP) Then
        ConsoleWrite("Healer triggered, sending key 2" & @CRLF)
        Send("2")
        Sleep($pottimer)
    EndIf

    ; Handle attack mode and no target logic
    If $AttackMode = 1 Then
        If $Type = -1 Then
            ConsoleWrite("No target found, sending Tab to switch target" & @CRLF)
            Send("{TAB}")
            Sleep(500)
        ElseIf $Type = 0 Or $Type = 1 Then
            ConsoleWrite("Player or Monster targeted, waiting..." & @CRLF)
            Sleep(500)
        ElseIf $Type = 2 Then
            ConsoleWrite("NPC targeted, sending key q" & @CRLF)
            Send("q")
            Sleep(500)
        EndIf
    EndIf
EndFunc
