#include "MemoryHandler.au3"
#include "GUIHandler.au3"
#include "CoordinateManager.au3"
#include "HealerAndLogging.au3"
#include <Misc.au3> ; Required for _IsPressed()

; Declare GUI control variables globally
Global $HealerLabel, $LoggingStatusLabel, $MapLogButton, $ExitButton, $KillButton

; Main Script Logic for RogueReader.au3
Global $ProcessName = "Project Rogue Client.exe"
Global $TypeOffset = 0xBEEA34
Global $PosXOffset = 0xBF1C6C
Global $PosYOffset = 0xBF1C64
Global $HPOffset = 0x9BE988
Global $MaxHPOffset = 0x9BE98C

InitializeCoordinateFile() ; Initialize the coordinates file at the start

; Create the main GUI and display it
$Gui = CreateMainGUI()
GUISetState(@SW_SHOW, $Gui) ; Ensure the GUI is shown

; Get the process ID
$ProcessID = ProcessExists($ProcessName)
If $ProcessID Then
    $MemOpen = _MemoryOpen($ProcessID)
    $BaseAddress = _EnumProcessModules($MemOpen)
    If $BaseAddress = 0 Then
        MsgBox(0, "Error", "Failed to get base address")
        Exit
    EndIf

    ; Calculate addresses
    $TypeAddress = $BaseAddress + $TypeOffset
    $PosXAddress = $BaseAddress + $PosXOffset
    $PosYAddress = $BaseAddress + $PosYOffset
    $HPAddress = $BaseAddress + $HPOffset
    $MaxHPAddress = $BaseAddress + $MaxHPOffset

    ; Main loop for the GUI and memory reading
    While 1
        $msg = GUIGetMsg()

        ; Handle healer toggle
        If _IsPressed("C0") Then
            ToggleHealer()
        EndIf

        ; Toggle logging status
        If $msg = $MapLogButton Then
            ToggleMapLogging()
        EndIf

        ; Kill the Rogue process if the Kill button is clicked
        If $msg = $KillButton Then
            ProcessClose($ProcessID)
            MsgBox(0, "Process", "Rogue Client Process Terminated.")
            Exit
        EndIf

        ; Log coordinates
        LogCoordinatesIfEnabled(_MemoryRead($PosXAddress, $MemOpen, "dword"), _MemoryRead($PosYAddress, $MemOpen, "dword"))

        ; Exit the script if Exit button is clicked
        If $msg = $ExitButton Then
            _MemoryClose($MemOpen)
            GUIDelete($Gui)
            Exit
        EndIf

        ; Refresh every 100 ms
        Sleep(100)
    WEnd
Else
    MsgBox(0, "Error", "Project Rogue Client.exe not found.")
EndIf
