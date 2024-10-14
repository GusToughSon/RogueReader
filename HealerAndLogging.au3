; Global variable declarations
Global $MemOpen, $PosXAddress, $PosYAddress, $LoggingStatus = "Off" ; Ensure $LoggingStatus is declared
Global $HealerStatus = False
Global $HealerLabel, $LoggingStatusLabel ; Declare these GUI controls as global

; Function to toggle the healer status
Func ToggleHealer()
    $HealerStatus = Not $HealerStatus
    If $HealerStatus Then
        GUICtrlSetData($HealerLabel, "Healer: ON")
    Else
        GUICtrlSetData($HealerLabel, "Healer: OFF")
    EndIf
EndFunc

; Function to toggle map logging status
Func ToggleMapLogging()
    ; Ensure $MemOpen is accessible and valid before using it
    If Not IsObj($MemOpen) Then
        ConsoleWrite("Memory not open." & @CRLF)
        Return
    EndIf

    Local $PosX = _MemoryRead($PosXAddress, $MemOpen, "dword")
    Local $PosY = _MemoryRead($PosYAddress, $MemOpen, "dword")
    LogCoordinatesToJson($PosX, $PosY, True) ; Call to log the coordinates

    ; Toggle the logging status
    If $LoggingStatus = "Off" Then
        $LoggingStatus = "On"
        GUICtrlSetData($LoggingStatusLabel, "Logging: On")
    Else
        $LoggingStatus = "Off"
        GUICtrlSetData($LoggingStatusLabel, "Logging: Off")
    EndIf
EndFunc

; Function to log coordinates to a JSON-like file
Func LogCoordinatesToJson($x, $y, $isPassable)
    Local $jsonFile = @ScriptDir & "\coordinates.json"
    Local $fileContents = ""

    ; Check if file exists and read its contents
    If FileExists($jsonFile) Then
        $fileContents = FileRead($jsonFile)
    EndIf

    ; Prepare new entry for X and Y coordinates
    Local $status = $isPassable ? "passable" : "solid"
    Local $entry = '{ "X": ' & $x & ', "Y": ' & $y & ', "status": "' & $status & '" },' & @CRLF

    ; Append the new entry to the file
    FileWrite($jsonFile, $fileContents & $entry)
EndFunc

; Function to check if logging is enabled and log the coordinates
Func LogCoordinatesIfEnabled($PosX, $PosY)
    If $LoggingStatus = "On" Then
        LogCoordinatesToJson($PosX, $PosY, True)
    EndIf
EndFunc
