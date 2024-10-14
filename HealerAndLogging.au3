Global $LoggingStatus = "Off" ; Initialize the logging status
Global $MemOpen, $PosXAddress, $PosYAddress, $HealerStatus ; Declare globals to avoid warnings

; Function to toggle map logging status
Func ToggleMapLogging()
    ; Ensure $MemOpen is accessible and valid before using it
    If Not IsObj($MemOpen) Then
        ConsoleWrite("Memory not open." & @CRLF)
        Return
    EndIf

    Local $PosX = _MemoryRead($PosXAddress, $MemOpen, "dword")
    Local $PosY = _MemoryRead($PosYAddress, $MemOpen, "dword")
    LogCoordinatesToBinary($PosX, $PosY, True) ; Call to log the coordinates in binary

    ; Toggle the logging status
    If $LoggingStatus = "Off" Then
        $LoggingStatus = "On"
        GUICtrlSetData($LoggingStatusLabel, "Logging: On")
    Else
        $LoggingStatus = "Off"
        GUICtrlSetData($LoggingStatusLabel, "Logging: Off")
    EndIf
EndFunc

; Function to log coordinates in binary
Func LogCoordinatesToBinary($x, $y, $isPassable)
    Local $status = $isPassable ? "passable" : "solid"
    UpdateBinaryCoordinate($x, $y, $status)
EndFunc

; Function to check if logging is enabled and log the coordinates
Func LogCoordinatesIfEnabled($PosX, $PosY)
    If $LoggingStatus = "On" Then
        LogCoordinatesToBinary($PosX, $PosY, True)
    EndIf
EndFunc

; Function to toggle the healer status
Func ToggleHealer()
    $HealerStatus = Not $HealerStatus
    If $HealerStatus Then
        GUICtrlSetData($HealerLabel, "Healer: ON")
    Else
        GUICtrlSetData($HealerLabel, "Healer: OFF")
    EndIf
EndFunc
