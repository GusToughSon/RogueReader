; Use the global variables from the GUI
Global $HealerStatus = False
Global $MapLoggingStatus = False
Global $LogTimer = TimerInit()

; Function to toggle the healer status
Func ToggleHealer()
    GUICtrlSetData($HealerLabel, "Healer: " & ($HealerStatus ? "OFF" : "ON"))
    $HealerStatus = Not $HealerStatus
    Sleep(300) ; Prevent rapid toggling
EndFunc

; Function to toggle map logging status
Func ToggleMapLogging()
    GUICtrlSetData($LoggingStatusLabel, "Logging: " & ($MapLoggingStatus ? "Off" : "On"))
    $MapLoggingStatus = Not $MapLoggingStatus
EndFunc

; Function to log coordinates every 5 seconds if logging is enabled
Func LogCoordinatesIfEnabled($PosX, $PosY)
    If $MapLoggingStatus And TimerDiff($LogTimer) > 5000 Then
        UpdateCoordinate($PosX, $PosY, "passable")
        $LogTimer = TimerInit()
    EndIf
EndFunc
