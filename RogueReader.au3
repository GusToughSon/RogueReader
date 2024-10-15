#include "MemoryReader.au3"     ; Memory reading and healer logic
#include "WaypointHandler.au3"   ; Waypoint navigation and movement logic
#include "GUIHandler.au3"        ; Handles GUI creation and updates
#include <Misc.au3>

Global $ProcessID, $MemOpen, $BaseAddress, $HealerStatus, $ThresholdSlider, $ProcessName, $ExitButton, $WaypointCountLabel, $CurrentWaypointLabel
Global $TargetFound = False     ; Flag to determine if a target exists
Global $Navigating = False      ; Flag to track if navigation is active
Global $DebugMode = True       ; Flag to control Debug Mode

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
HotKeySet("F12", "ToggleDebugMode") ; Set F12 as the hotkey to toggle Debug Mode

; Debugging process identification
DebugWrite("Attempting to find process: " & $ProcessName & @CRLF)
$ProcessID = ProcessExists($ProcessName)

If $ProcessID = 0 Then
    DebugWrite("Error: Process not found: " & $ProcessName & @CRLF)
    MsgBox(0, "Error", "Process not found: " & $ProcessName)
    Exit
Else
    DebugWrite("Process found with ID: " & $ProcessID & @CRLF)
EndIf

; Open the memory process
DebugWrite("Attempting to open memory for process ID: " & $ProcessID & @CRLF)
$MemOpen = OpenMemoryProcess($ProcessID)

If $MemOpen = 0 Then
    DebugWrite("Error: Failed to open memory for process ID: " & $ProcessID & @CRLF)
    MsgBox(0, "Error", "Failed to open memory for process.")
    Exit
Else
    DebugWrite("Memory process opened successfully." & @CRLF)
EndIf

; Ensure base address is retrieved here and shared
DebugWrite("Attempting to retrieve base address for process..." & @CRLF)
$BaseAddress = GetBaseAddress($MemOpen)

If $BaseAddress = 0 Then
    DebugWrite("Error: Failed to retrieve base address." & @CRLF)
    MsgBox(0, "Error", "Failed to retrieve base address.")
    Exit
Else
    DebugWrite("Base address retrieved successfully: 0x" & Hex($BaseAddress) & @CRLF)
EndIf

; Main loop for handling logic and memory reading
While 1
    $msg = GUIGetMsg()

    ; Check if the Exit button is clicked
    If $msg = $ExitButton Then
        DebugWrite("Exit button clicked. Closing memory handle and exiting..." & @CRLF)
        _MemoryClose($MemOpen)  ; Close memory handle
        Exit                    ; Exit the script
    EndIf

    ; Check if we have a valid target before proceeding to waypoints
    DebugWrite("Reading target type from memory..." & @CRLF)
    $Type = _MemoryRead($BaseAddress + $TypeOffset, $MemOpen, "dword")

    If $Type > 0 Then
        ; We found a valid target (Player, Monster, NPC)
        DebugWrite("Target found with type: " & $Type & @CRLF)
        $TargetFound = True
        ProcessTargeting($Type) ; Handle targeting logic
    Else
        ; No valid target found, prioritize waypoints
        DebugWrite("No valid target found. Proceeding with waypoint navigation if active." & @CRLF)
        $TargetFound = False
        If $Navigating Then
            ContinueNavigation()  ; Proceed with waypoint navigation if no target
        EndIf
    EndIf

    ; Handle healer logic only if it's "on"
    If $HealerStatus Then
        DebugWrite("Healer is ON. Processing healer logic..." & @CRLF)
        ProcessHealer($MemOpen, $pottimer, $BaseAddress)
    Else
        DebugWrite("Healer is OFF." & @CRLF)
    EndIf

    ; Sleep for a short period to avoid hogging CPU
    Sleep(50)
WEnd

Func ToggleHealer()
    $HealerStatus = Not $HealerStatus
    If $HealerStatus Then
        DebugWrite("Healer ON" & @CRLF)
        GUICtrlSetData($HealerLabel, "Healer: ON")
    Else
        DebugWrite("Healer OFF" & @CRLF)
        GUICtrlSetData($HealerLabel, "Healer: OFF")
    EndIf
EndFunc

Func ProcessHealer($MemOpen, $pottimer, $BaseAddress)
    ; Ensure healer is only working when it's supposed to be "on"
    DebugWrite("Reading HP and MaxHP from memory..." & @CRLF)
    $HP = _MemoryRead($BaseAddress + $HPOffset, $MemOpen, "dword")
    $MaxHP = _MemoryRead($BaseAddress + $MaxHPOffset, $MemOpen, "dword")
    $HP2 = $HP / 65536

    DebugWrite("HP: " & $HP & " | MaxHP: " & $MaxHP & " | HP2: " & $HP2 & @CRLF)

    If $HealerStatus And ($HP2 <= (GUICtrlRead($ThresholdSlider) / 100)) Then
        DebugWrite("HP is below the threshold. Sending heal action (2)..." & @CRLF)
        Send("2")  ; Send the healing action
        Sleep($pottimer)
    Else
        DebugWrite("HP is above the threshold. No heal action needed." & @CRLF)
    EndIf
EndFunc

Func ProcessTargeting($Type)
    ; Placeholder targeting logic
    DebugWrite("Processing target of type: " & $Type & @CRLF)

    ; Add targeting logic based on $Type here (e.g., player, monster, etc.)
    If $Type = 1 Then
        ; Monster
        Send("{tab}")  ; Example key to target
    ElseIf $Type = 2 Then
        ; NPC
        ; Add relevant action here
    EndIf
EndFunc

Func ToggleDebugMode()
    $DebugMode = Not $DebugMode
    If $DebugMode Then
        ConsoleWrite("Debug Mode: ON" & @CRLF)
    Else
        ConsoleWrite("Debug Mode: OFF" & @CRLF)
    EndIf
EndFunc

Func DebugWrite($text)
    If $DebugMode Then
        ConsoleWrite($text)
    EndIf
EndFunc
