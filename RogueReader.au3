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

    $BaseAddress = _EnumProcessModules($MemOpen)

    If $BaseAddress = 0 Then
        If $DebugMode Then ConsoleWrite("Error: Failed to get base address" & @CRLF)
        MsgBox(0, "Error", "Failed to get base address")
        Exit
    EndIf

    If $DebugMode Then ConsoleWrite("Base Address: " & Hex($BaseAddress) & @CRLF)

    $TypeAddress = $BaseAddress + 0xBEEA34
    $AttackModeAddress = $BaseAddress + 0xAC0D60
    $ChatStatusAddress = $BaseAddress + 0x9B5998
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

    Select
        Case $msg = $ExitButton
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
    EndSelect

    $SliderValue = GUICtrlRead($Slider)
    GUICtrlSetData($SliderLabel, "Heal if HP below: " & $SliderValue & "%")

    $RefreshRate = GUICtrlRead($RefreshSlider)
    GUICtrlSetData($RefreshLabel, "Refresh Rate: " & $RefreshRate & "ms")

    Local $Type = _MemoryRead($TypeAddress, $MemOpen, "dword")
    Local $AttackMode = _MemoryRead($AttackModeAddress, $MemOpen, "dword")
    Local $ChatStatus = _MemoryRead($ChatStatusAddress, $MemOpen, "dword")

    If $AttackMode = 1 And $Type = 65535 And $ChatStatus = 0 Then
        If WinActive("Project Rogue") Then
            ControlSend("Project Rogue", "", "", "{TAB}")
            Sleep(100)
        EndIf
    EndIf

    Local $PosX = _MemoryRead($PosXAddress, $MemOpen, "dword")
    Local $PosY = _MemoryRead($PosYAddress, $MemOpen, "dword")
    Local $HP = _MemoryRead($HPAddress, $MemOpen, "dword")
    Local $MaxHP = _MemoryRead($MaxHPAddress, $MemOpen, "dword")

    GUICtrlSetData($PosXLabel, "Pos X: " & $PosX)
    GUICtrlSetData($PosYLabel, "Pos Y: " & $PosY)
    GUICtrlSetData($HPLabel, "HP: " & $HP)
    GUICtrlSetData($MaxHPLabel, "MaxHP: " & $MaxHP)

    Local $HP2 = Round($HP / 65536, 2)
    GUICtrlSetData($HP2Label, "HP2: " & $HP2)

    If $HealerStatus And $ChatStatus = 0 And $HP2 <= ($SliderValue / 100 * $MaxHP) Then
        ControlSend("", "", "", "2")
        Sleep($pottimer)
    EndIf

    If $WaypointActive And $WaypointCount > 0 Then
        NavigateToWaypoint($Waypoints[$CurrentWaypointIndex][0], $Waypoints[$CurrentWaypointIndex][1])

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
    EndIf

    Sleep($RefreshRate)
WEnd

; ---------------------------- Functions ----------------------------

Func _EnumProcessModules($hProcess)
    Local $hMod = DllStructCreate("ptr")
    Local $moduleSize = DllStructGetSize($hMod)

    Local $aModules = DllCall("psapi.dll", "int", "EnumProcessModulesEx", "ptr", $hProcess, "ptr", DllStructGetPtr($hMod), "dword", $moduleSize, "dword*", 0, "dword", 0x03)

    If IsArray($aModules) And $aModules[0] <> 0 Then
        Return DllStructGetData($hMod, 1)
    Else
        Return 0
    EndIf
EndFunc

Func ToggleHealer()
    $HealerStatus = Not $HealerStatus
    GUICtrlSetData($HealerLabel, "Healer: " & ($HealerStatus ? "ON" : "OFF"))
EndFunc

Func SetHealerHotkey()
    Local $newHotkey = InputBox("Set Healer Hotkey", "Press the new key for the healer hotkey:")

    If StringLen($newHotkey) > 0 Then
        HotKeySet($HealerHotkey)
        $HealerHotkey = $newHotkey
        HotKeySet($HealerHotkey, "ToggleHealer")
        GUICtrlSetData($HotkeyLabel, "Healer Hotkey: " & $HealerHotkey)
        IniWrite($configFile, "Settings", "HealerHotkey", $HealerHotkey)
    EndIf
EndFunc

Func SetWaypointHotkey()
    Local $newHotkey = InputBox("Set Waypoint Hotkey", "Press the new key for the set waypoint hotkey:")

    If StringLen($newHotkey) > 0 Then
        HotKeySet($SetWaypointHotkey)
        $SetWaypointHotkey = $newHotkey
        HotKeySet($SetWaypointHotkey, "SetWaypoint")
        IniWrite($configFile, "Settings", "SetWaypointHotkey", $SetWaypointHotkey)
    EndIf
EndFunc

Func SetStartWaypointHotkey()
    Local $newHotkey = InputBox("Start Waypoints Hotkey", "Press the new key for the start waypoints hotkey:")

    If StringLen($newHotkey) > 0 Then
        HotKeySet($StartWaypointHotkey)
        $StartWaypointHotkey = $newHotkey
        HotKeySet($StartWaypointHotkey, "StartWaypoints")
        IniWrite($configFile, "Settings", "StartWaypointHotkey", $StartWaypointHotkey)
    EndIf
EndFunc

Func SetStopWaypointHotkey()
    Local $newHotkey = InputBox("Stop Waypoints Hotkey", "Press the new key for the stop waypoints hotkey:")

    If StringLen($newHotkey) > 0 Then
        HotKeySet($StopWaypointHotkey)
        $StopWaypointHotkey = $newHotkey
        HotKeySet($StopWaypointHotkey, "StopWaypoints")
        IniWrite($configFile, "Settings", "StopWaypointHotkey", $StopWaypointHotkey)
    EndIf
EndFunc

Func SetResetWaypointHotkey()
    Local $newHotkey = InputBox("Reset Waypoints Hotkey", "Press the new key for the reset waypoints hotkey:")

    If StringLen($newHotkey) > 0 Then
        HotKeySet($ResetWaypointHotkey)
        $ResetWaypointHotkey = $newHotkey
        HotKeySet($ResetWaypointHotkey, "ResetWaypoints")
        IniWrite($configFile, "Settings", "ResetWaypointHotkey", $ResetWaypointHotkey)
    EndIf
EndFunc

Func SetWaypoint()
    If $WaypointCount < $MAX_WAYPOINTS Then
        $Waypoints[$WaypointCount][0] = $PosX
        $Waypoints[$WaypointCount][1] = $PosY
        $WaypointCount += 1
        GUICtrlSetData($WaypointStatusLabel, "Waypoints Set: " & $WaypointCount & " | Active: " & ($WaypointActive ? "ON" : "OFF"))
        IniWrite($configFile, "Waypoints", "X" & ($WaypointCount - 1), $Waypoints[$WaypointCount - 1][0])
        IniWrite($configFile, "Waypoints", "Y" & ($WaypointCount - 1), $Waypoints[$WaypointCount - 1][1])
        IniWrite($configFile, "Waypoints", "Count", $WaypointCount)
    Else
        MsgBox(0, "Waypoint Limit Reached", "You have reached the maximum of " & $MAX_WAYPOINTS & " waypoints.")
    EndIf
EndFunc

Func StartWaypoints()
    If $WaypointCount = 0 Then
        MsgBox(0, "No Waypoints", "Please set at least one waypoint before starting navigation.")
        Return
    EndIf
    $WaypointActive = True
    GUICtrlSetData($WaypointStatusLabel, "Waypoints Set: " & $WaypointCount & " | Active: ON")
    IniWrite($configFile, "Settings", "WaypointActive", "1")
EndFunc

Func StopWaypoints()
    $WaypointActive = False
    GUICtrlSetData($WaypointStatusLabel, "Waypoints Set: " & $WaypointCount & " | Active: OFF")
    IniWrite($configFile, "Settings", "WaypointActive", "0")
EndFunc

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
EndFunc

Func ToggleWaypoints()
    If $WaypointActive Then
        StopWaypoints()
    Else
        $WaypointMode = GUICtrlRead($ModeDropdown)
        StartWaypoints()
    EndIf
EndFunc

Func NavigateToWaypoint($targetX, $targetY)
    Local $currentX = _MemoryRead($PosXAddress, $MemOpen, "dword")
    Local $currentY = _MemoryRead($PosYAddress, $MemOpen, "dword")

    Local $distX = $targetX - $currentX
    Local $distY = $targetY - $currentY

    Local $tolerance = 5

    While Abs($distX) > $tolerance Or Abs($distY) > $tolerance
        $distX = $targetX - $currentX
        $distY = $targetY - $currentY

        If $distX > $tolerance Then
            ControlSend("Project Rogue", "", "", "{D down}")
            Sleep(50)
            ControlSend("Project Rogue", "", "", "{D up}")
        ElseIf $distX < -$tolerance Then
            ControlSend("Project Rogue", "", "", "{A down}")
            Sleep(50)
            ControlSend("Project Rogue", "", "", "{A up}")
        EndIf

        If $distY > $tolerance Then
            ControlSend("Project Rogue", "", "", "{W down}")
            Sleep(50)
            ControlSend("Project Rogue", "", "", "{W up}")
        ElseIf $distY < -$tolerance Then
            ControlSend("Project Rogue", "", "", "{S down}")
            Sleep(50)
            ControlSend("Project Rogue", "", "", "{S up}")
        EndIf

        $currentX = _MemoryRead($PosXAddress, $MemOpen, "dword")
        $currentY = _MemoryRead($PosYAddress, $MemOpen, "dword")
    WEnd

    Sleep(1000)
EndFunc

Func SaveSettings()
    IniWrite($configFile, "Settings", "HealPercentage", GUICtrlRead($Slider))
    IniWrite($configFile, "Settings", "HealerHotkey", $HealerHotkey)
    IniWrite($configFile, "Settings", "RefreshRate", GUICtrlRead($RefreshSlider))
    IniWrite($configFile, "Settings", "WaypointMode", $WaypointMode)
    IniWrite($configFile, "Settings", "WaypointActive", $WaypointActive ? "1" : "0")

    IniWrite($configFile, "Waypoints", "Count", $WaypointCount)
    For $i = 0 To $WaypointCount - 1
        IniWrite($configFile, "Waypoints", "X" & $i, $Waypoints[$i][0])
        IniWrite($configFile, "Waypoints", "Y" & $i, $Waypoints[$i][1])
    Next
EndFunc
