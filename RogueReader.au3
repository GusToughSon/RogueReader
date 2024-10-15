#include "MemoryHandler.au3"  ; Handles memory operations
#include "GUIHandler.au3"      ; Handles GUI creation

Global $ProcessID, $MemOpen, $BaseAddress, $HealerStatus, $ThresholdSlider  ; Declare necessary global variables

; Pot timer (pottimer) set to 2000 ms
Global $pottimer = 2000

; Initialize HealerStatus and other necessary variables
$HealerStatus = False

; Create GUI and start the main loop
CreateGUI()  ; Calls GUIHandler to create the GUI

$ProcessID = ProcessExists($ProcessName)
$MemOpen = OpenMemoryProcess($ProcessID) ; Calls MemoryHandler to open the process

If $MemOpen = 0 Then
    MsgBox(0, "Error", "Project Rogue Client.exe not found.")
    Exit
EndIf

; Ensure base address is retrieved here and shared
$BaseAddress = GetBaseAddress($MemOpen)

If $BaseAddress = 0 Then
    MsgBox(0, "Error", "Failed to get base address. Exiting.")
    Exit
EndIf

; Main loop for handling logic and memory reading
While 1
    $msg = GUIGetMsg()

    ; Handle memory reading and logic
    ProcessLogic($MemOpen, $pottimer, $BaseAddress)  ; Pass the base address to the handler

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
WEnd

; Clean up GUI on exit
GUIDelete($Gui)
