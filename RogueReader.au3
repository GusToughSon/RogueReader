#include "MemoryReader.au3"     ; Memory reading and healer logic
#include "WaypointHandler.au3"   ; Waypoint navigation and movement logic
#include "GUIHandler.au3"        ; Handles GUI creation and updates
#include <Misc.au3>

Global $ProcessID, $MemOpen, $BaseAddress, $HealerStatus, $ThresholdSlider, $ProcessName, $ExitButton, $WaypointCountLabel, $CurrentWaypointLabel

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
HotKeySet("`", "ToggleHealer") ; Set the hotkey for healer functionality (backtick key)

$ProcessID = ProcessExists($ProcessName)
$MemOpen = OpenMemoryProcess($ProcessID) ; Calls MemoryReader to open the process

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

    ; Handle healer logic and other memory operations
    ProcessLogic($MemOpen, $pottimer, $BaseAddress)  ; Call memory reader logic

    ; Sleep for a short period to avoid hogging CPU
    Sleep(50)
WEnd

Func ToggleHealer()
    $HealerStatus = Not $HealerStatus
    If $HealerStatus Then
        ConsoleWrite("Healer ON" & @CRLF)
        GUICtrlSetData($HealerLabel, "Healer: ON")
    Else
        ConsoleWrite("Healer OFF" & @CRLF)
        GUICtrlSetData($HealerLabel, "Healer: OFF")
    EndIf
EndFunc
