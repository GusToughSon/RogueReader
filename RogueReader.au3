#include "MemoryHandler.au3"  ; Handles memory operations
#include "GUIHandler.au3"      ; Handles GUI creation
#include <Misc.au3>

Global $ProcessID, $MemOpen, $BaseAddress, $HealerStatus, $ThresholdSlider, $ProcessName, $ExitButton  ; Added $ExitButton to global variables

; Process Name
$ProcessName = "Project Rogue Client.exe"

; Pot timer (pottimer) set to 2000 ms
Global $pottimer = 2000

; Initialize HealerStatus and other necessary variables
$HealerStatus = False

; Create GUI and start the main loop
CreateGUI()  ; Calls GUIHandler to create the GUI

; Set Hotkeys
HotKeySet("\", "SetWaypoint")   ; Hotkey to set waypoints
HotKeySet("]", "WipeWaypoints") ; Hotkey to wipe waypoints
HotKeySet("/", "StartNavigation") ; Hotkey to start navigation
HotKeySet("'", "TogglePauseNavigation") ; Hotkey to pause/resume navigation

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

    ; Check if the Exit button is clicked
    If $msg = $ExitButton Then
        _MemoryClose($MemOpen)  ; Close memory handle
        Exit                    ; Exit the script
    EndIf

    ; Check if attack mode switches to safe, stop navigation
    $AttackMode = _MemoryRead($BaseAddress + $AttackModeOffset, $MemOpen, "dword")
    If $AttackMode = 0 Then
        $Navigating = False
        GUICtrlSetData($CurrentWaypointLabel, "Navigating to Waypoint: N/A")
    EndIf

    ; Handle other logic, such as healer, etc.
    ProcessLogic($MemOpen, $pottimer, $BaseAddress)  ; Call memory handler

    ; Sleep for a short period to avoid hogging CPU
    Sleep(50)
WEnd
