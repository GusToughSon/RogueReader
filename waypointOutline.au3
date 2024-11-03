#include <File.au3>
#include <NomadMemory.au3>

Global Const $LOCATION_FILE = @ScriptDir & "\LocationLog.cfg"

; Initialize the location file and ensure it exists
Func InitializeLog()
    If Not FileExists($LOCATION_FILE) Then
        Local $file = FileOpen($LOCATION_FILE, 2)
        FileClose($file)
    EndIf
EndFunc

; Function to log position to the location file, avoids duplicate consecutive entries
Func LogPosition($PosXAddress, $PosYAddress, $MemOpen)
    InitializeLog()
    Local $PosX = _MemoryRead($PosXAddress, $MemOpen, "dword")
    Local $PosY = _MemoryRead($PosYAddress, $MemOpen, "dword")
    Local $currentPositions = GetLoggedPositions()
    Local $entry = "X: " & $PosX & ", Y: " & $PosY & ","

    ; Check if last entry is the same as the new entry
    If UBound($currentPositions) > 0 And $currentPositions[UBound($currentPositions) - 1] = $entry Then
        Return
    EndIf

    ; Check if the log has reached 1000 entries
    If UBound($currentPositions) >= 1000 Then
        Return
    EndIf

    ; Open the file to write the new entry
    Local $file = FileOpen($LOCATION_FILE, 1)
    If $file = -1 Then
        Return
    EndIf
    FileWriteLine($file, $entry)
    FileClose($file)
EndFunc

; Function to clear the location file
Func ClearPositionLog()
    Local $file = FileOpen($LOCATION_FILE, 2)
    If $file = -1 Then
        Return
    EndIf
    FileClose($file)
    FileDelete($LOCATION_FILE)
    InitializeLog()
EndFunc

; Helper function to get logged positions from the location file
Func GetLoggedPositions()
    InitializeLog()
    Local $fileContents = FileReadToArray($LOCATION_FILE)

    If @error Then
        Return ""
    EndIf

    If IsArray($fileContents) Then
        Return $fileContents
    Else
        Return ""
    EndIf
EndFunc

; Usage example:
; Assume $MemOpen is a valid handle to the memory process obtained from _MemoryOpen.
; LogPosition($PosXAddress, $PosYAddress, $MemOpen) ; This will log the position read from memory addresses.
; ClearPositionLog() ; Clears the entire location file.
