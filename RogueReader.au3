#include "MemoryReader.au3"     ; Memory reading and healer logic
#include "WaypointHandler.au3"   ; Waypoint navigation and movement logic
#include "GUIHandler.au3"        ; Handles GUI creation and updates
#include <Misc.au3>

Global $ProcessID, $MemOpen, $BaseAddress, $HealerStatus, $ThresholdSlider, $ProcessName, $ExitButton, $WaypointCountLabel, $CurrentWaypointLabel
Global $TargetFound = False     ; Flag to determine if a target exists
Global $Navigating = False      ; Flag to track if navigation is active

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

    ; Check if we have a valid target before proceeding to waypoints
    $Type = _MemoryRead($BaseAddress + $TypeOffset, $MemOpen, "dword")

    If $Type > 0 Then
        ; We found a valid target (Player, Monster, NPC)
        $TargetFound = True
        ProcessTargeting($Type) ; Handle targeting logic
    Else
        ; No valid target found, prioritize waypoints
        $TargetFound = False
        If $Navigating Then
            ContinueNavigation()  ; Proceed with waypoint navigation if no target
        EndIf
    EndIf

    ; Handle healer logic only if it's "on"
    If $HealerStatus Then
        ProcessHealer($MemOpen, $pottimer, $BaseAddress)
    EndIf

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

Func ProcessHealer($MemOpen, $pottimer, $BaseAddress)
    ; Ensure healer is only working when it's supposed to be "on"
    $HP = _MemoryRead($BaseAddress + $HPOffset, $MemOpen, "dword")
    $MaxHP = _MemoryRead($BaseAddress + $MaxHPOffset, $MemOpen, "dword")
    $HP2 = $HP / 65536

    If $HealerStatus And ($HP2 <= (GUICtrlRead($ThresholdSlider) / 100)) Then
        Send("2")  ; Send the healing action
        Sleep($pottimer)
    EndIf
EndFunc

Func ProcessTargeting($Type)
    ; Placeholder targeting logic
    ConsoleWrite("Processing target of type: " & $Type & @CRLF)

    ; Add targeting logic based on $Type here (e.g., player, monster, etc.)
    If $Type = 1 Then
        ; Monster
        Send("{tab}")  ; Example key to target
    ElseIf $Type = 2 Then
        ; NPC
        ; Add relevant action here
    EndIf
EndFunc
