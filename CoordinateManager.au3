#include <File.au3>

Global $MaxCoordinate = 7000
Global $CoordinateFile = @ScriptDir & "\coordinates.json"

; Function to initialize the coordinate file with X and Y values from 0 to 7000 marked as "solid" by default
Func InitializeCoordinateFile()
    ; Check if the coordinate file already exists and is not blank
    If FileExists($CoordinateFile) Then
        Local $fileSize = FileGetSize($CoordinateFile)
        If $fileSize > 0 Then
            ConsoleWrite("Coordinate file already exists. Initialization skipped." & @CRLF)
            Return
        EndIf
    EndIf

    ; Create the coordinate file and initialize all X, Y values
    Local $fileHandle = FileOpen($CoordinateFile, 2)
    If $fileHandle = -1 Then
        MsgBox(0, "Error", "Failed to create the coordinate file.")
        Exit
    EndIf

    ; Begin JSON structure
    FileWrite($fileHandle, "{" & @CRLF)

    ; Loop through X and Y from 0 to $MaxCoordinate and set them as solid
    For $x = 0 To $MaxCoordinate
        For $y = 0 To $MaxCoordinate
            FileWrite($fileHandle, '"X' & $x & 'Y' & $y & '": "solid"')
            If Not ($x = $MaxCoordinate And $y = $MaxCoordinate) Then
                FileWrite($fileHandle, "," & @CRLF)
            EndIf
        Next
    Next

    FileWrite($fileHandle, @CRLF & "}")
    FileClose($fileHandle)
    ConsoleWrite("Coordinate file created and initialized." & @CRLF)
EndFunc

; Function to update a specific X, Y coordinate in the file to mark it as "passable"
Func UpdateCoordinate($x, $y, $status = "passable")
    If Not FileExists($CoordinateFile) Then
        ConsoleWrite("Error: Coordinate file not found." & @CRLF)
        Return
    EndIf
    Local $fileContents = FileRead($CoordinateFile)
    Local $coordinatePattern = '"X' & $x & 'Y' & $y & '": "solid"'
    $fileContents = StringReplace($fileContents, $coordinatePattern, '"X' & $x & 'Y' & $y & '": "' & $status & '"')
    FileDelete($CoordinateFile)
    FileWrite($CoordinateFile, $fileContents)
EndFunc
