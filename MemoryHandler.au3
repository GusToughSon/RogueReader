#include "NomadMemory.au3"
#include <Misc.au3>

Global $Waypoints[20][2]  ; Array to store up to 20 waypoints (X and Y)
Global $WaypointCount = 0  ; Keep track of how many waypoints are set
Global $CurrentWaypoint = 0  ; Track the current waypoint being navigated to
Global $Navigating = False  ; Flag to track if navigation is active
Global $Paused = False  ; Flag to track if navigation is paused
Global $TypeOffset = 0xBEEA34
Global $AttackModeOffset = 0xAC0D60
Global $PosXOffset = 0xBF1C58
Global $PosYOffset = 0xBF1C50
Global $HPOffset = 0x9BE988
Global $MaxHPOffset = 0x9BE98C
Global $WaypointCountLabel, $CurrentWaypointLabel, $BaseAddress, $MemOpen, $ThresholdSlider, $HealerStatus  ; Declare GUI-related variables and memory access variables

Func OpenMemoryProcess($ProcessID)
    If $ProcessID Then
        Return _MemoryOpen($ProcessID)
    Else
        Return 0
    EndIf
EndFunc

Func GetBaseAddress($hProcess)
    Local $hMod = DllStructCreate("ptr") ; Create a structure for a pointer (64-bit)
    Local $moduleSize = DllStructGetSize($hMod)

    ; Call EnumProcessModules to list modules
    Local $aModules = DllCall("psapi.dll", "int", "EnumProcessModulesEx", "ptr", $hProcess, "ptr", DllStructGetPtr($hMod), "dword", $moduleSize, "dword*", 0, "dword", 0x03)

    If @error Or $aModules[0] = 0 Then
        Return 0
    EndIf

    ; Retrieve the base address from the module
    $BaseAddress = DllStructGetData($hMod, 1)
    Return $BaseAddress
EndFunc

Func ProcessLogic($MemOpen, $pottimer, $BaseAddress)
    ; Ensure $BaseAddress has been properly set
    If $BaseAddress = 0 Then
        Return
    EndIf

    ; Read memory and process game logic
    $Type = _MemoryRead($BaseAddress + $TypeOffset, $MemOpen, "dword")
    $AttackMode = _MemoryRead($BaseAddress + $AttackModeOffset, $MemOpen, "dword")
    $PosX = _MemoryRead($BaseAddress + $PosXOffset, $MemOpen, "dword")
    $PosY = _MemoryRead($BaseAddress + $PosYOffset, $MemOpen, "dword")
    $HP = _MemoryRead($BaseAddress + $HPOffset, $MemOpen, "dword")
    $MaxHP = _MemoryRead($BaseAddress + $MaxHPOffset, $MemOpen, "dword")

    ; Update GUI with the new data (using GUIHandler functions)
    UpdateGUI($Type, $AttackMode, $PosX, $PosY, $HP, $MaxHP)

    ; Handle healer logic
    If $HealerStatus And ($HP / 65536) <= (GUICtrlRead($ThresholdSlider) / 100 * $MaxHP) Then
        Send("2")
        Sleep($pottimer)
    EndIf

    ; Handle navigation logic
    If $Navigating Then
        ; Perform navigation logic using the waypoints
    EndIf
EndFunc

Func SetWaypoint()
    If $WaypointCount < 20 Then
        $PosX = _MemoryRead($BaseAddress + $PosXOffset, $MemOpen, "dword")
        $PosY = _MemoryRead($BaseAddress + $PosYOffset, $MemOpen, "dword")

        ; Check if the new waypoint is the same as the previous one
        If $WaypointCount > 0 And $Waypoints[$WaypointCount - 1][0] = $PosX And $Waypoints[$WaypointCount - 1][1] = $PosY Then
            MsgBox(0, "Duplicate Waypoint", "This waypoint is the same as the last one. Please set a different location.")
            Return
        EndIf

        ; Add new waypoint
        $Waypoints[$WaypointCount][0] = $PosX
        $Waypoints[$WaypointCount][1] = $PosY
        $WaypointCount += 1

        ; Update GUI with waypoint count
        GUICtrlSetData($WaypointCountLabel, "Waypoints: " & $WaypointCount)

        MsgBox(0, "Waypoint Set", "Waypoint #" & $WaypointCount & " set at X: " & $PosX & ", Y: " & $PosY)
    Else
        MsgBox(0, "Error", "Maximum number of waypoints reached.")
    EndIf
EndFunc

Func WipeWaypoints()
    ; Reset all waypoints
    For $i = 0 To 19
        $Waypoints[$i][0] = 0
        $Waypoints[$i][1] = 0
    Next
    $WaypointCount = 0
    $CurrentWaypoint = 0
    $Navigating = False

    ; Update GUI
    GUICtrlSetData($WaypointCountLabel, "Waypoints: 0")
    GUICtrlSetData($CurrentWaypointLabel, "Navigating to Waypoint: N/A")

    MsgBox(0, "Waypoints Cleared", "All waypoints have been wiped.")
EndFunc

Func StartNavigation()
    If $WaypointCount = 0 Then
        MsgBox(0, "Error", "No waypoints set. Use the '\' hotkey to set waypoints.")
        Return
    EndIf

    $Navigating = True
    $CurrentWaypoint = 0

    For $i = 0 To $WaypointCount - 1
        ; Break if navigation is stopped or paused
        If Not $Navigating Then ExitLoop

        ; Navigate to each waypoint
        $CurrentWaypoint = $i + 1
        GUICtrlSetData($CurrentWaypointLabel, "Navigating to Waypoint: " & $CurrentWaypoint)
        MoveToWaypoint($Waypoints[$i][0], $Waypoints[$i][1])

        ; Random pause between 2-5 seconds
        Sleep(Random(2000, 5000))
    Next

    ; Navigate in reverse back to the first waypoint
    For $i = $WaypointCount - 1 To 0 Step -1
        If Not $Navigating Then ExitLoop

        $CurrentWaypoint = $i + 1
        GUICtrlSetData($CurrentWaypointLabel, "Navigating to Waypoint: " & $CurrentWaypoint)
        MoveToWaypoint($Waypoints[$i][0], $Waypoints[$i][1])
        Sleep(Random(2000, 5000))
    Next

    $Navigating = False
    GUICtrlSetData($CurrentWaypointLabel, "Navigating to Waypoint: N/A")
EndFunc

Func MoveToWaypoint($TargetX, $TargetY)
    While True
        ; Break if navigation is paused or stopped
        If Not $Navigating Or $Paused Then ExitLoop

        ; Read current position
        $PosX = _MemoryRead($BaseAddress + $PosXOffset, $MemOpen, "dword")
        $PosY = _MemoryRead($BaseAddress + $PosYOffset, $MemOpen, "dword")

        ; Calculate distance to target
        $DeltaX = $TargetX - $PosX
        $DeltaY = $TargetY - $PosY

        ; If we are within ±5 coordinates, stop moving
        If Abs($DeltaX) <= 5 And Abs($DeltaY) <= 5 Then
            ExitLoop
        EndIf

        ; Move left or right
        If $DeltaX > 5 Then
            Send("d")  ; Move right
        ElseIf $DeltaX < -5 Then
            Send("a")  ; Move left
        EndIf

        ; Move up or down
        If $DeltaY > 5 Then
            Send("w")  ; Move up
        ElseIf $DeltaY < -5 Then
            Send("s")  ; Move down
        EndIf

        ; Sleep for a short period before checking again
        Sleep(100)
    WEnd
EndFunc

Func TogglePauseNavigation()
    If $Navigating Then
        $Paused = Not $Paused
        If $Paused Then
            MsgBox(0, "Navigation Paused", "Navigation has been paused.")
        Else
            MsgBox(0, "Navigation Resumed", "Navigation has resumed.")
        EndIf
    EndIf
EndFunc
