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
    ConsoleWrite("Error: Project Rogue Client.exe not found." & @CRLF)
    Exit
EndIf

; Use the correct window title: "Project Rogue"
$WindowTitle = "Project Rogue"

If $WindowTitle = "" Then
    ConsoleWrite("Error: Could not find the window for Project Rogue." & @CRLF)
    Exit
EndIf

ConsoleWrite("Window found: " & $WindowTitle & @CRLF)

; Ensure base address is retrieved here and shared
$BaseAddress = GetBaseAddress($MemOpen)

If $BaseAddress = 0 Then
    ConsoleWrite("Error: Failed to get base address. Exiting." & @CRLF)
    Exit
EndIf

ConsoleWrite("Base address retrieved: " & Hex($BaseAddress) & @CRLF)

; Main loop for handling logic and memory reading
While 1
    $msg = GUIGetMsg()

    ; Check if the Exit button is clicked
    If $msg = $ExitButton Then
        _MemoryClose($MemOpen)  ; Close memory handle
        ConsoleWrite("Exiting script." & @CRLF)
        Exit                    ; Exit the script
    EndIf

    ; Read the current target type (0 = Player, 1 = Monster, 2 = NPC)
    $Type = _MemoryRead($BaseAddress + $TypeOffset, $MemOpen, "dword")
    ConsoleWrite("Target Type: " & $Type & @CRLF)

    ; Check if attack mode switches to safe, stop navigation
    $AttackMode = _MemoryRead($BaseAddress + $AttackModeOffset, $MemOpen, "dword")
    ConsoleWrite("Attack Mode: " & $AttackMode & @CRLF)

    If $AttackMode = 0 Then
        $Navigating = False
        GUICtrlSetData($CurrentWaypointLabel, "Navigating to Waypoint: N/A")
        ConsoleWrite("Attack mode set to Safe. Stopping navigation." & @CRLF)
    EndIf

    ; Handle attack logic based on the target type (attack monsters or NPCs)
    If $AttackMode = 1 Then
        If $Type = 1 Then
            ConsoleWrite("Target is a Monster. Initiating attack..." & @CRLF)
            Send("{2}") ; Example key for attacking
        ElseIf $Type = 2 Then
            ConsoleWrite("Target is an NPC. Initiating attack..." & @CRLF)
            Send("{2}") ; Example key for attacking
        ElseIf $Type = 0 Then
            ConsoleWrite("Target is a Player. No attack." & @CRLF)
        Else
            ; Check if the Project Rogue window is active
            If WinActive($WindowTitle) Then
                ConsoleWrite("No valid target. Switching target..." & @CRLF)
                Send("{Tab}") ; Switch target
                Sleep(50) ; Small delay
            Else
                ConsoleWrite("Project Rogue is not the active window. Skipping tab switch." & @CRLF)
            EndIf
        EndIf
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
