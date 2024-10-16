#include "NomadMemory.au3"
#include <GUIConstantsEx.au3>
#include <Misc.au3>
#include <File.au3>
#include <Array.au3>

; ---------------------------- Global Variables ----------------------------

Global $pottimer = 2000
Global $DebugMode = False ; Set to True to enable debug console outputs
Global $configFile = @ScriptDir & "\config.ini" ; Path to the config file
Global $HealerStatus = False
Global $HealerHotkey = "`" ; Default hotkey for healer
Global $RefreshRate = 50 ; Default refresh rate (50ms)

; Waypoint System Variables
Global Const $MAX_WAYPOINTS = 250
Global $Waypoints[$MAX_WAYPOINTS][2] = [[0, 0]]
Global $WaypointCount = 0
Global $WaypointMode = "Loop" ; Default mode
Global $WaypointActive = False
Global $CurrentWaypointIndex = 0
Global $PingPongDirection = 1 ; 1 for forward, -1 for backward
Global $SetWaypointHotkey = "F1"
Global $StartWaypointHotkey = "F4"
Global $StopWaypointHotkey = "F5"
Global $ResetWaypointHotkey = "F3"

; ComboBox Select String Constant
Global Const $CB_SELECTSTRING = 0x014F

; ---------------------------- Configuration Management ----------------------------

; Check if the config file exists; if not, create it with default settings
If Not FileExists($configFile) Then
    IniWrite($configFile, "Settings", "HealPercentage", "95")
    IniWrite($configFile, "Settings", "HealerHotkey", $HealerHotkey)
    IniWrite($configFile, "Settings", "RefreshRate", "50")
    IniWrite($configFile, "Settings", "WaypointMode", $WaypointMode)
    IniWrite($configFile, "Settings", "WaypointActive", "0")
    IniWrite($configFile, "Settings", "SetWaypointHotkey", $SetWaypointHotkey)
    IniWrite($configFile, "Settings", "StartWaypointHotkey", $StartWaypointHotkey)
    IniWrite($configFile, "Settings", "StopWaypointHotkey", $StopWaypointHotkey)
    IniWrite($configFile, "Settings", "ResetWaypointHotkey", $ResetWaypointHotkey)
    IniWrite($configFile, "Waypoints", "Count", "0")
EndIf

; Read settings from config file
Local $SliderValue = IniRead($configFile, "Settings", "HealPercentage", "95")
$HealerHotkey = IniRead($configFile, "Settings", "HealerHotkey", "`")
$RefreshRate = IniRead($configFile, "Settings", "RefreshRate", "50")
$WaypointMode = IniRead($configFile, "Settings", "WaypointMode", "Loop")
$WaypointActive = (IniRead($configFile, "Settings", "WaypointActive", "0") = "1") ; Convert to Boolean
$WaypointCount = IniRead($configFile, "Waypoints", "Count", "0")
$SetWaypointHotkey = IniRead($configFile, "Settings", "SetWaypointHotkey", "F1")
$StartWaypointHotkey = IniRead($configFile, "Settings", "StartWaypointHotkey", "F4")
$StopWaypointHotkey = IniRead($configFile, "Settings", "StopWaypointHotkey", "F5")
$ResetWaypointHotkey = IniRead($configFile, "Settings", "ResetWaypointHotkey", "F3")

; Load waypoints from config file
For $i = 0 To $WaypointCount - 1
    $Waypoints[$i][0] = IniRead($configFile, "Waypoints", "X" & $i, "0")
    $Waypoints[$i][1] = IniRead($configFile, "Waypoints", "Y" & $i, "0")
Next

; ---------------------------- Hotkey Registration ----------------------------

HotKeySet($HealerHotkey, "ToggleHealer")
HotKeySet($SetWaypointHotkey, "SetWaypoint")
HotKeySet($StartWaypointHotkey, "StartWaypoints")
HotKeySet($StopWaypointHotkey, "StopWaypoints")
HotKeySet($ResetWaypointHotkey, "ResetWaypoints")

; ---------------------------- GUI Creation ----------------------------

$Gui = GUICreate("RogueReader", 450, 600, 15, 15)
Local $TypeLabel = GUICtrlCreateLabel("Type: N/A", 20, 30, 250, 20)
Local $AttackModeLabel = GUICtrlCreateLabel("Attack Mode: N/A", 20, 60, 250, 20)
Local $PosXLabel = GUICtrlCreateLabel("Pos X: N/A", 20, 90, 250, 20)
Local $PosYLabel = GUICtrlCreateLabel("Pos Y: N/A", 20, 120, 250, 20)
Local $HPLabel = GUICtrlCreateLabel("HP: N/A", 20, 150, 250, 20)
Local $HP2Label = GUICtrlCreateLabel("HP2: N/A", 20, 180, 250, 20)
Local $MaxHPLabel = GUICtrlCreateLabel("MaxHP: N/A", 20, 210, 250, 20)
Local $HealerLabel = GUICtrlCreateLabel("Healer: OFF", 20, 240, 250, 20)
Local $HotkeyLabel = GUICtrlCreateLabel("Healer Hotkey: " & $HealerHotkey, 20, 270, 250, 20)
Local $ChangeHotkeyButton = GUICtrlCreateButton("Change Hotkey", 280, 270, 150, 30)
Local $PotsNote = GUICtrlCreateLabel("Pots go in #2", 20, 300, 250, 20)

; Slider for dynamic healing percentage
Local $SliderLabel = GUICtrlCreateLabel("Heal if HP below: " & $SliderValue & "%", 20, 330, 250, 20)
Local $Slider = GUICtrlCreateSlider(20, 360, 200, 30)
GUICtrlSetLimit($Slider, 100, 50)
GUICtrlSetData($Slider, $SliderValue)

; Slider for refresh rate (50ms to 150ms)
Local $RefreshLabel = GUICtrlCreateLabel("Refresh Rate: " & $RefreshRate & "ms", 20, 400, 250, 20)
Local $RefreshSlider = GUICtrlCreateSlider(20, 430, 200, 30)
GUICtrlSetLimit($RefreshSlider, 150, 50) ; 50ms to 150ms
GUICtrlSetData($RefreshSlider, $RefreshRate)

; Buttons
Local $KillButton = GUICtrlCreateButton("Kill Rogue", 20, 480, 100, 30)
Local $ExitButton = GUICtrlCreateButton("Exit", 150, 480, 100, 30)

; ---------------------------- Waypoint System GUI Controls ----------------------------

Local $SetWaypointButton = GUICtrlCreateButton("Set Waypoint", 20, 520, 150, 30)
Local $StartWaypointButton = GUICtrlCreateButton("Start Waypoints", 180, 520, 150, 30)
Local $StopWaypointButton = GUICtrlCreateButton("Stop Waypoints", 20, 560, 150, 30)
Local $ResetWaypointsButton = GUICtrlCreateButton("Reset Waypoints", 180, 560, 150, 30)

Local $ModeLabel = GUICtrlCreateLabel("Waypoint Mode:", 20, 510, 150, 20)
Local $ModeDropdown = GUICtrlCreateCombo("", 200, 510, 200, 30)
GUICtrlSetData($ModeDropdown, "Loop|PingPong")
GUICtrlSetData($ModeDropdown, $WaypointMode) ; Set selection based on loaded mode

Local $WaypointStatusLabel = GUICtrlCreateLabel("Waypoints Set: " & $WaypointCount & " | Active: " & ($WaypointActive ? "ON" : "OFF"), 20, 600, 300, 20)

GUISetState(@SW_SHOW)

; ---------------------------- Process and Memory Initialization ----------------------------

$ProcessID = ProcessExists("Project Rogue Client.exe")
If $ProcessID Then
    If $DebugMode Then ConsoleWrite("Process found. Process ID: " & $ProcessID & @CRLF)
    $MemOpen = _MemoryOpen($ProcessID)

    ; Get the base address of the main module (Project Rogue Client.exe)
    $BaseAddress = _EnumProcessModules($MemOpen)

    If $BaseAddress = 0 Then
        If $DebugMode Then ConsoleWrite("Error: Failed to get base address" & @CRLF)
        MsgBox(0, "Error", "Failed to get base address")
        Exit
    EndIf

    If $DebugMode Then ConsoleWrite("Base Address: " & Hex($BaseAddress) & @CRLF)

    ; Define memory addresses based on base address
    $TypeAddress = $BaseAddress + 0xBEEA34
    $AttackModeAddress = $BaseAddress + 0xAC0D60
    $ChatStatusAddress = $BaseAddress + 0x9B5998 ; Chat memory address
    $PosXAddress = $BaseAddress + 0xBF1C6C
    $PosYAddress = $BaseAddress + 0xBF1C64
    $HPAddress = $BaseAddress + 0x9BE988
    $MaxHPAddress = $BaseAddress + 0x9BE98C
Else
    MsgBox(0, "Error", "Project Rogue Client.exe not found.")
    Exit
EndIf

; ---------------------------- Main Loop ----------------------------

While 1
    Local $msg = GUIGetMsg()

    ; Handle GUI Events
    Select
        Case $msg = $ExitButton
            ; Save settings and waypoints before exiting
            SaveSettings()
            _MemoryClose($MemOpen)
            Exit

        Case $msg = $KillButton
            ProcessClose($ProcessID)
            Exit

        Case $msg = $ChangeHotkeyButton
            SetHealerHotkey()

        Case $msg = $SetWaypointButton
            SetWaypointHotkey()

        Case $msg = $StartWaypointButton
            SetStartWaypointHotkey()

        Case $msg = $StopWaypointButton
            SetStopWaypointHotkey()

        Case $msg = $ResetWaypointsButton
            SetResetWaypointHotkey()

        Case $msg = $ModeDropdown
            $WaypointMode = GUICtrlRead($ModeDropdown)
            If $DebugMode Then ConsoleWrite("Waypoint mode set to " & $WaypointMode & @CRLF)
    EndSelect

    ; Update Slider Labels Dynamically
    $SliderValue = GUICtrlRead($Slider)
    GUICtrlSetData($SliderLabel, "Heal if HP below: " & $SliderValue & "%")

    $RefreshRate = GUICtrlRead($RefreshSlider)
    GUICtrlSetData($RefreshLabel, "Refresh Rate: " & $RefreshRate & "ms")

    ; Reading memory for Type, Attack Mode, and Chat Status
    Local $Type = _MemoryRead($TypeAddress, $MemOpen, "dword")
    Local $AttackMode = _MemoryRead($AttackModeAddress, $MemOpen, "dword")
    Local $ChatStatus = _MemoryRead($ChatStatusAddress, $MemOpen, "dword")

    ; Debugging for Attack Mode, Type, and Chat Status
    If $DebugMode Then
        ConsoleWrite("Attack Mode: " & $AttackMode & " | Type: " & $Type & " | Chat Status: " & $ChatStatus & @CRLF)
    EndIf

    ; Update Type Label
    Switch $Type
        Case 0
            GUICtrlSetData($TypeLabel, "Type: Player")
        Case 1
            GUICtrlSetData($TypeLabel, "Type: Monster")
        Case 2
            GUICtrlSetData($TypeLabel, "Type: NPC")
        Case 65535
            GUICtrlSetData($TypeLabel, "Type: No Target")
        Case Else
            GUICtrlSetData($TypeLabel, "Type: Unknown (" & $Type & ")")
    EndSwitch

    ; Attack Mode status update
    GUICtrlSetData($AttackModeLabel, "Attack Mode: " & ($AttackMode ? "Attack" : "Safe"))

    ; Tab Targeting for No Target (65535), only if chat is not open
    If $AttackMode = 1 And $Type = 65535 And $ChatStatus = 0 Then
        If $DebugMode Then ConsoleWrite("No target, sending TAB to acquire a target." & @CRLF)
        If WinActive("Project Rogue") Then
            ControlSend("Project Rogue", "", "", "{TAB}")
            Sleep(100)
        Else
            If $DebugMode Then ConsoleWrite("Project Rogue is not the active window." & @CRLF)
        EndIf
    ElseIf $ChatStatus = 1 Then
        If $DebugMode Then ConsoleWrite("Chat is open, pausing tab targeting." & @CRLF)
    ElseIf $AttackMode = 1 And ($Type = 0 Or $Type = 1) Then
        If $DebugMode Then ConsoleWrite("Player or Monster is targeted, no TAB sent." & @CRLF)
    EndIf

    ; Read and display PosX, PosY, HP, and MaxHP
    Local $PosX = _MemoryRead($PosXAddress, $MemOpen, "dword")
    Local $PosY = _MemoryRead($PosYAddress, $MemOpen, "dword")
    Local $HP = _MemoryRead($HPAddress, $MemOpen, "dword")
    Local $MaxHP = _MemoryRead($MaxHPAddress, $MemOpen, "dword")

    If $DebugMode Then ConsoleWrite("Pos X: " & $PosX & ", Pos Y: " & $PosY & ", HP: " & $HP & ", Max HP: " & $MaxHP & @CRLF)

    GUICtrlSetData($PosXLabel, "Pos X: " & $PosX)
    GUICtrlSetData($PosYLabel, "Pos Y: " & $PosY)
    GUICtrlSetData($HPLabel, "HP: " & $HP)
    GUICtrlSetData($MaxHPLabel, "MaxHP: " & $MaxHP)

    Local $HP2 = Round($HP / 65536, 2) ; Adjusted HP value if needed
    GUICtrlSetData($HP2Label, "HP2: " & $HP2)

    ; Auto-Healing Logic
    If $HealerStatus And $ChatStatus = 0 And $HP2 <= ($SliderValue / 100 * $MaxHP) Then
        If $DebugMode Then ConsoleWrite("HP below threshold. Using healing potion." & @CRLF)
        ControlSend("", "", "", "2") ; Assuming '2' selects the healing potion
        Sleep($pottimer)
    ElseIf $ChatStatus = 1 Then
        If $DebugMode Then ConsoleWrite("Chat is open, pausing healing." & @CRLF)
    EndIf

    ; Waypoint Navigation Logic
    If $WaypointActive And $WaypointCount > 0 Then
        NavigateToWaypoint($Waypoints[$CurrentWaypointIndex][0], $Waypoints[$CurrentWaypointIndex][1])

        ; Move to the next waypoint based on the selected mode
        If $WaypointMode = "Loop" Then
            $CurrentWaypointIndex = Mod($CurrentWaypointIndex + 1, $WaypointCount)
        ElseIf $WaypointMode = "PingPong" Then
            $CurrentWaypointIndex += $PingPongDirection
            If $CurrentWaypointIndex >= $WaypointCount - 1 Then
                $PingPongDirection = -1
            ElseIf $CurrentWaypointIndex <= 0 Then
                $PingPongDirection = 1
            EndIf
        EndIf

        If $DebugMode Then ConsoleWrite("Navigating to waypoint " & ($CurrentWaypointIndex + 1) & ": (" & $Waypoints[$CurrentWaypointIndex][0] & ", " & $Waypoints[$CurrentWaypointIndex][1] & ")" & @CRLF)
    EndIf

    Sleep($RefreshRate)
WEnd

; ---------------------------- Functions ----------------------------

; Function to Enumerate Process Modules and Get Base Address
Func _EnumProcessModules($hProcess)
    Local $hMod = DllStructCreate("ptr") ; 64-bit pointer
    Local $moduleSize = DllStructGetSize($hMod)

    ; Call EnumProcessModulesEx to list modules
    Local $aModules = DllCall("psapi.dll", "int", "EnumProcessModulesEx", "ptr", $hProcess, "ptr", DllStructGetPtr($hMod), "dword", $moduleSize, "dword*", 0, "dword", 0x03)

    If IsArray($aModules) And $aModules[0] <> 0 Then
        Return DllStructGetData($hMod, 1) ; Return base address
    Else
        Return 0
    EndIf
EndFunc

; Function to Toggle Healer Status
Func ToggleHealer()
    $HealerStatus = Not $HealerStatus
    GUICtrlSetData($HealerLabel, "Healer: " & ($HealerStatus ? "ON" : "OFF"))
    If $DebugMode Then ConsoleWrite("Healer toggled to " & ($HealerStatus ? "ON" : "OFF") & @CRLF)
EndFunc

; Function to Set a New Healer Hotkey
Func SetHealerHotkey()
    ; Prompt the user to press a key for the new hotkey
    Local $newHotkey = InputBox("Set Healer Hotkey", "Press the new key for the healer hotkey:")

    If StringLen($newHotkey) > 0 Then
        ; Unset the previous hotkey
        HotKeySet($HealerHotkey)

        ; Set the new hotkey
        $HealerHotkey = $newHotkey
        HotKeySet($HealerHotkey, "ToggleHealer")

        ; Update the GUI and save to config
        GUICtrlSetData($HotkeyLabel, "Healer Hotkey: " & $HealerHotkey)
        IniWrite($configFile, "Settings", "HealerHotkey", $HealerHotkey)

        If $DebugMode Then ConsoleWrite("Healer hotkey changed to " & $HealerHotkey & @CRLF)
    EndIf
EndFunc

; Function to Set a New Set Waypoint Hotkey
Func SetWaypointHotkey()
    ; Prompt the user to press a key for the new hotkey
    Local $newHotkey = InputBox("Set Waypoint Hotkey", "Press the new key for the set waypoint hotkey:")

    If StringLen($newHotkey) > 0 Then
        ; Unset the previous hotkey
        HotKeySet($SetWaypointHotkey)

        ; Set the new hotkey
        $SetWaypointHotkey = $newHotkey
        HotKeySet($SetWaypointHotkey, "SetWaypoint")

        ; Save to config
        IniWrite($configFile, "Settings", "SetWaypointHotkey", $SetWaypointHotkey)

        If $DebugMode Then ConsoleWrite("Set Waypoint hotkey changed to " & $SetWaypointHotkey & @CRLF)
    EndIf
EndFunc

; Function to Set a New Start Waypoint Hotkey
Func SetStartWaypointHotkey()
    ; Prompt the user to press a key for the new hotkey
    Local $newHotkey = InputBox("Start Waypoints Hotkey", "Press the new key for the start waypoints hotkey:")

    If StringLen($newHotkey) > 0 Then
        ; Unset the previous hotkey
        HotKeySet($StartWaypointHotkey)

        ; Set the new hotkey
        $StartWaypointHotkey = $newHotkey
        HotKeySet($StartWaypointHotkey, "StartWaypoints")

        ; Save to config
        IniWrite($configFile, "Settings", "StartWaypointHotkey", $StartWaypointHotkey)

        If $DebugMode Then ConsoleWrite("Start Waypoints hotkey changed to " & $StartWaypointHotkey & @CRLF)
    EndIf
EndFunc

; Function to Set a New Stop Waypoint Hotkey
Func SetStopWaypointHotkey()
    ; Prompt the user to press a key for the new hotkey
    Local $newHotkey = InputBox("Stop Waypoints Hotkey", "Press the new key for the stop waypoints hotkey:")

    If StringLen($newHotkey) > 0 Then
        ; Unset the previous hotkey
        HotKeySet($StopWaypointHotkey)

        ; Set the new hotkey
        $StopWaypointHotkey = $newHotkey
        HotKeySet($StopWaypointHotkey, "StopWaypoints")

        ; Save to config
        IniWrite($configFile, "Settings", "StopWaypointHotkey", $StopWaypointHotkey)

        If $DebugMode Then ConsoleWrite("Stop Waypoints hotkey changed to " & $StopWaypointHotkey & @CRLF)
    EndIf
EndFunc

; Function to Set a New Reset Waypoint Hotkey
Func SetResetWaypointHotkey()
    ; Prompt the user to press a key for the new hotkey
    Local $newHotkey = InputBox("Reset Waypoints Hotkey", "Press the new key for the reset waypoints hotkey:")

    If StringLen($newHotkey) > 0 Then
        ; Unset the previous hotkey
        HotKeySet($ResetWaypointHotkey)

        ; Set the new hotkey
        $ResetWaypointHotkey = $newHotkey
        HotKeySet($ResetWaypointHotkey, "ResetWaypoints")

        ; Save to config
        IniWrite($configFile, "Settings", "ResetWaypointHotkey", $ResetWaypointHotkey)

        If $DebugMode Then ConsoleWrite("Reset Waypoints hotkey changed to " & $ResetWaypointHotkey & @CRLF)
    EndIf
EndFunc

; Function to Set a New Waypoint
Func SetWaypoint()
    If $WaypointCount < $MAX_WAYPOINTS Then
        $Waypoints[$WaypointCount][0] = $PosX
        $Waypoints[$WaypointCount][1] = $PosY
        $WaypointCount += 1
        GUICtrlSetData($WaypointStatusLabel, "Waypoints Set: " & $WaypointCount & " | Active: " & ($WaypointActive ? "ON" : "OFF"))
        IniWrite($configFile, "Waypoints", "X" & ($WaypointCount - 1), $Waypoints[$WaypointCount - 1][0])
        IniWrite($configFile, "Waypoints", "Y" & ($WaypointCount - 1), $Waypoints[$WaypointCount - 1][1])
        IniWrite($configFile, "Waypoints", "Count", $WaypointCount)
        If $DebugMode Then ConsoleWrite("Waypoint " & $WaypointCount & " set at (" & $Waypoints[$WaypointCount - 1][0] & ", " & $Waypoints[$WaypointCount - 1][1] & ")" & @CRLF)
    Else
        MsgBox(0, "Waypoint Limit Reached", "You have reached the maximum of " & $MAX_WAYPOINTS & " waypoints.")
        If $DebugMode Then ConsoleWrite("Attempted to set waypoint beyond limit." & @CRLF)
    EndIf
EndFunc

; Function to Start Waypoint Navigation
Func StartWaypoints()
    If $WaypointCount = 0 Then
        MsgBox(0, "No Waypoints", "Please set at least one waypoint before starting navigation.")
        If $DebugMode Then ConsoleWrite("Attempted to start waypoint navigation with no waypoints set." & @CRLF)
        Return
    EndIf
    $WaypointActive = True
    GUICtrlSetData($WaypointStatusLabel, "Waypoints Set: " & $WaypointCount & " | Active: ON")
    IniWrite($configFile, "Settings", "WaypointActive", "1")
    If $DebugMode Then ConsoleWrite("Waypoint navigation started in " & $WaypointMode & " mode." & @CRLF)
EndFunc

; Function to Stop Waypoint Navigation
Func StopWaypoints()
    $WaypointActive = False
    GUICtrlSetData($WaypointStatusLabel, "Waypoints Set: " & $WaypointCount & " | Active: OFF")
    IniWrite($configFile, "Settings", "WaypointActive", "0")
    If $DebugMode Then ConsoleWrite("Waypoint navigation stopped." & @CRLF)
EndFunc

; Function to Reset All Waypoints
Func ResetWaypoints()
    For $i = 0 To $MAX_WAYPOINTS - 1
        $Waypoints[$i][0] = 0
        $Waypoints[$i][1] = 0
    Next
    $WaypointCount = 0
    $WaypointActive = False
    $CurrentWaypointIndex = 0
    $PingPongDirection = 1
    GUICtrlSetData($WaypointStatusLabel, "Waypoints Set: 0 | Active: OFF")
    IniWrite($configFile, "Waypoints", "Count", "0")
    IniWrite($configFile, "Settings", "WaypointActive", "0")
    If $DebugMode Then ConsoleWrite("All waypoints have been reset." & @CRLF)
EndFunc

; Function to Toggle Waypoint Navigation
Func ToggleWaypoints()
    If $WaypointActive Then
        StopWaypoints()
    Else
        $WaypointMode = GUICtrlRead($ModeDropdown)
        StartWaypoints()
    EndIf
EndFunc

; Function to Navigate to a Specific Waypoint
Func NavigateToWaypoint($x, $y)
    ; Placeholder implementation:
    ; Adjust this function based on how Project Rogue handles movement commands.
    ; For example, send a "/goto X Y" command via chat or use in-game APIs.

    ; Example using ControlSend to send chat commands:
    ; ControlSend("Project Rogue", "", "", "/goto " & $x & " " & $y & "{ENTER}")

    ; Alternatively, simulate mouse movements or other in-game interactions.

    ; For demonstration, we'll simulate a delay representing navigation time.
    Sleep(1000) ; Simulate time taken to navigate
EndFunc

; Function to Save Settings and Waypoints to Config File
Func SaveSettings()
    ; Save healing and refresh settings
    IniWrite($configFile, "Settings", "HealPercentage", GUICtrlRead($Slider))
    IniWrite($configFile, "Settings", "HealerHotkey", $HealerHotkey)
    IniWrite($configFile, "Settings", "RefreshRate", GUICtrlRead($RefreshSlider))
    IniWrite($configFile, "Settings", "WaypointMode", $WaypointMode)
    IniWrite($configFile, "Settings", "WaypointActive", $WaypointActive ? "1" : "0")

    ; Save waypoints
    IniWrite($configFile, "Waypoints", "Count", $WaypointCount)
    For $i = 0 To $WaypointCount - 1
        IniWrite($configFile, "Waypoints", "X" & $i, $Waypoints[$i][0])
        IniWrite($configFile, "Waypoints", "Y" & $i, $Waypoints[$i][1])
    Next

    If $DebugMode Then ConsoleWrite("Settings and waypoints saved to config.ini." & @CRLF)
EndFunc

; ---------------------------- End of Script ----------------------------
