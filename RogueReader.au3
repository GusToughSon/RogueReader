#include "MemoryHandler.au3"
#include "GUIHandler.au3"
#include "CoordinateManager.au3"
#include "HealerAndLogging.au3"
#include <Misc.au3> ; Required for _IsPressed()

; Global variable declarations
Global $PosXAddress, $PosYAddress, $MemOpen
Global $LoggingStatus = "Off" ; Initialize the logging status
Global $MapLogButton, $KillButton, $ExitButton ; Declare these GUI controls as global

; Game process and memory offsets
Global $ProcessName = "Project Rogue Client.exe"
Global $TypeOffset = 0xBEEA34
Global $PosXOffset = 0xBF1C6C
Global $PosYOffset = 0xBF1C64
Global $HPOffset = 0x9BE988
Global $MaxHPOffset = 0x9BE98C

; Initialize coordinate files
InitializeCoordinateFiles()

; Create the main GUI and display it
$Gui = CreateMainGUI()
GUISetState(@SW_SHOW, $Gui) ; Ensure the GUI is shown

; Get the process ID
$ProcessID = ProcessExists($ProcessName)
If $ProcessID Then
    $MemOpen = _MemoryOpen($ProcessID)
    If $MemOpen = 0 Then
        ; Memory could not be opened, display a popup and exit
        MsgBox(0, "Error", "Failed to open memory for the process.")
        Exit
    EndIf

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

        ; Log coordinates if logging is enabled
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
    MsgBox(0, "Error", "Project Rogue Client.exe not found.") ; Show error popup if the process is not found
EndIf
