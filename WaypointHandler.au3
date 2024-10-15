Global $Waypoints[50][2]  ; Array to store up to 50 waypoints (X and Y)
Global $WaypointCount = 0  ; Keep track of how many waypoints are set
Global $CurrentWaypoint = 0  ; Track the current waypoint being navigated to
Global $Navigating = False  ; Flag to track if navigation is active
Global $Paused = False  ; Flag to track if navigation is paused
Global $Direction = -1  ; Direction for ping-pong navigation (-1 for down, 1 for up)
Global $BaseAddress, $MemOpen, $WaypointCountLabel, $CurrentWaypointLabel

Func SetWaypoint()
    If $WaypointCount < 50 Then
        $PosX = _MemoryRead($BaseAddress + $PosXOffset, $MemOpen, "dword")
        $PosY = _MemoryRead($BaseAddress + $PosYOffset, $MemOpen, "dword")

        ; Check if the new waypoint is the same as the previous one
        If $WaypointCount > 0 And $Waypoints[$WaypointCount - 1][0] = $PosX And $Waypoints[$WaypointCount - 1][1] = $PosY Then
            Return  ; Ignore if the waypoint is a duplicate
        EndIf

        ; Add new waypoint
        $Waypoints[$WaypointCount][0] = $PosX
        $Waypoints[$WaypointCount][1] = $PosY
        $WaypointCount += 1

        ; Update GUI with waypoint count
        GUICtrlSetData($WaypointCountLabel, "Waypoints: " & $WaypointCount)

    Else
        MsgBox(0, "Error", "Maximum number of waypoints (50) reached.")
    EndIf
EndFunc

Func WipeWaypoints()
    ; Reset all waypoints
    For $i = 0 To 49
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
    $CurrentWaypoint = $WaypointCount - 1  ; Start at the last waypoint set
    $Direction = -1  ; Start moving down the list of waypoints

    While $Navigating
        ; Update GUI with current waypoint information
        GUICtrlSetData($CurrentWaypointLabel, "Navigating to Waypoint: " & ($CurrentWaypoint + 1))

        ; Move to the current waypoint
        MoveToWaypoint($Waypoints[$CurrentWaypoint][0], $Waypoints[$CurrentWaypoint][1])

        ; Random pause between waypoints
        Sleep(Random(500, 1500))

        ; Adjust current waypoint for ping-pong navigation
        If $Direction = -1 Then
            $CurrentWaypoint -= 1
            If $CurrentWaypoint < 0 Then
                $CurrentWaypoint = 1
                $Direction = 1  ; Change direction to up
            EndIf
        ElseIf $Direction = 1 Then
            $CurrentWaypoint += 1
            If $CurrentWaypoint >= $WaypointCount Then
                $CurrentWaypoint = $WaypointCount - 2
                $Direction = -1  ; Change direction to down
            EndIf
        EndIf
    WEnd
EndFunc

Func MoveToWaypoint($TargetX, $TargetY)
    ConsoleWrite("Starting navigation to Waypoint - Target X: " & $TargetX & ", Target Y: " & $TargetY & @CRLF)

    Local $LastPosX = 0, $LastPosY = 0, $StuckCount = 0

    While True
        ; Check if navigation is paused or stopped
        If Not $Navigating Then
            ConsoleWrite("Navigation stopped." & @CRLF)
            ExitLoop
        EndIf

        ; Read current position from memory
        $PosX = _MemoryRead($BaseAddress + $PosXOffset, $MemOpen, "dword")
        $PosY = _MemoryRead($BaseAddress + $PosYOffset, $MemOpen, "dword")

        ; Log current position
        ConsoleWrite("Current Position - X: " & $PosX & ", Y: " & $PosY & @CRLF)

        ; Calculate the differences (deltas) between current and target positions
        $DeltaX = $TargetX - $PosX
        $DeltaY = $TargetY - $PosY

        ; Log the calculated deltas
        ConsoleWrite("Calculated Delta - X: " & $DeltaX & ", Y: " & $DeltaY & @CRLF)

        ; Stuck detection: check if the player is in the same spot repeatedly
        If $PosX = $LastPosX And $PosY = $LastPosY Then
            $StuckCount += 1
        Else
            $StuckCount = 0
        EndIf

        $LastPosX = $PosX
        $LastPosY = $PosY

        ; If stuck for more than 10 iterations, attempt alternate movement
        If $StuckCount > 10 Then
            ConsoleWrite("Stuck detected, attempting alternate movement." & @CRLF)
            If $DeltaX <> 0 Then
                ; Try moving perpendicular if stuck on X axis
                Send("{w down}")
                Sleep(100)
                Send("{w up}")
            ElseIf $DeltaY <> 0 Then
                ; Try moving perpendicular if stuck on Y axis
                Send("{d down}")
                Sleep(100)
                Send("{d up}")
            EndIf
            $StuckCount = 0 ; Reset stuck counter after attempt
            ContinueLoop
        EndIf

        ; Stricter condition to check if we've reached the target (within ±1 range)
        If Abs($DeltaX) <= 1 And Abs($DeltaY) <= 1 Then
            ConsoleWrite("Reached waypoint. Stopping movement." & @CRLF)
            ExitLoop
        EndIf

        ; Prioritize movement based on the larger delta (either X or Y)
        If Abs($DeltaX) > Abs($DeltaY) Then
            ; Handle X movement first (A and D control X-axis)
            If $DeltaX < -1 Then
                ConsoleWrite("Moving left (A = -X)" & @CRLF)
                Send("{a down}")
                Sleep(100)
                Send("{a up}")
            ElseIf $DeltaX > 1 Then
                ConsoleWrite("Moving right (D = +X)" & @CRLF)
                Send("{d down}")
                Sleep(100)
                Send("{d up}")
            EndIf
        Else
            ; Handle Y movement (W and S control Y-axis)
            If $DeltaY < -1 Then
                ConsoleWrite("Moving up (W = -Y)" & @CRLF)
                Send("{w down}")
                Sleep(100)
                Send("{w up}")
            ElseIf $DeltaY > 1 Then
                ConsoleWrite("Moving down (S = +Y)" & @CRLF)
                Send("{s down}")
                Sleep(100)
                Send("{s up}")
            EndIf
        EndIf

        ; Sleep briefly before checking again
        Sleep(100)
    WEnd

    ConsoleWrite("Finished navigating to waypoint." & @CRLF)
EndFunc

Func TogglePauseNavigation()
    If $Navigating Then
        $Paused = Not $Paused
        If $Paused Then
            ConsoleWrite("Navigation Paused." & @CRLF)
        Else
            ConsoleWrite("Navigation Resumed." & @CRLF)
        EndIf
    EndIf
EndFunc
