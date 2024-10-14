#include <File.au3>
#include <JSON.au3> ; Ensure to include the JSON library

Global $MaxCoordinate = 7000
Global $ChunkSize = 50 ; Each chunk will have 50 x 50 coordinates, totaling 2500 entries
Global $CoordinateDir = @ScriptDir & "\coordinates\"
Global $IndexFile = $CoordinateDir & "index.json"

; Function to initialize the coordinate directory and files
Func InitializeCoordinateFiles()
    ; Create the coordinate directory if it doesn't exist
    If Not FileExists($CoordinateDir) Then
        DirCreate($CoordinateDir)
    EndIf

    ; Initialize index
    If Not FileExists($IndexFile) Then
        FileWrite($IndexFile, "{}") ; Create an empty index
    EndIf

    ; Loop through X and Y to create chunk files
    For $xChunk = 0 To Floor($MaxCoordinate / $ChunkSize)
        For $yChunk = 0 To Floor($MaxCoordinate / $ChunkSize)
            Local $fileName = "coordinates_" & $xChunk & "_" & $yChunk & ".json"
            Local $fullPath = $CoordinateDir & $fileName

            ; Check if the file already exists
            If Not FileExists($fullPath) Then
                InitializeChunkFile($fullPath, $xChunk, $yChunk)
                Sleep(500) ; Sleep for 500 milliseconds between file creations
            EndIf
        Next
    Next

    ConsoleWrite("Coordinate files initialized." & @CRLF)
EndFunc

; Function to initialize a specific chunk file
Func InitializeChunkFile($fullPath, $xChunk, $yChunk)
    Local $fileHandle = FileOpen($fullPath, 2) ; Open file in write mode
    If $fileHandle = -1 Then
        MsgBox(0, "Error", "Failed to create the chunk file.")
        Exit
    EndIf

    ; Begin JSON structure
    FileWrite($fileHandle, "{" & @CRLF)

    ; Loop through coordinates in the chunk
    For $x = $xChunk * $ChunkSize To $xChunk * $ChunkSize + $ChunkSize - 1
        For $y = $yChunk * $ChunkSize To $yChunk * $ChunkSize + $ChunkSize - 1
            If $x <= $MaxCoordinate And $y <= $MaxCoordinate Then ; Check bounds
                FileWrite($fileHandle, '"X' & $x & 'Y' & $y & '": "solid"')
                If Not ($x = $xChunk * $ChunkSize + $ChunkSize - 1 And $y = $yChunk * $ChunkSize + $ChunkSize - 1) Then
                    FileWrite($fileHandle, "," & @CRLF)
                EndIf
            EndIf
        Next
    Next

    ; End JSON structure
    FileWrite($fileHandle, @CRLF & "}")
    FileClose($fileHandle)

    ; Update the index
    UpdateIndexFile($xChunk, $yChunk, $fullPath)
EndFunc

; Function to update the index file
Func UpdateIndexFile($xChunk, $yChunk, $fullPath)
    Local $indexContents = FileRead($IndexFile)

    ; Print the index contents for debugging
    ConsoleWrite("Index file contents: " & $indexContents & @CRLF)

    ; Initialize the JSON object
    Local $json
    If StringStripWS($indexContents, 0) = "" Then
        $json = Json_Decode("{}") ; Initialize as an empty object if the file is empty
    Else
        $json = Json_Decode($indexContents) ; Decode current index content
        If Not IsObj($json) Then
            ; If decoding fails, create a new JSON object
            ConsoleWrite("Error decoding JSON, initializing empty object." & @CRLF)
            $json = Json_Decode("{}")
        EndIf
    EndIf

    ; Ensure $json is an object before proceeding
    If Not IsObj($json) Then
        MsgBox(0, "Error", "Unable to create or update JSON index.")
        Return
    EndIf

    ; Add new entry for the chunk
    Local $chunkKey = "X" & $xChunk & "Y" & $yChunk
    $json[$chunkKey] = $fullPath ; Map chunk to its file path

    ; Write updated index
    FileDelete($IndexFile)
    FileWrite($IndexFile, Json_Encode($json)) ; Encode and save the updated index
EndFunc

; Function to update a specific X, Y coordinate in the chunk file
Func UpdateCoordinate($x, $y, $status = "passable")
    Local $xChunk = Floor($x / $ChunkSize)
    Local $yChunk = Floor($y / $ChunkSize)
    Local $chunkFileName = "coordinates_" & $xChunk & "_" & $yChunk & ".json"
    Local $fullPath = $CoordinateDir & $chunkFileName

    If Not FileExists($fullPath) Then
        ConsoleWrite("Error: Chunk file not found." & @CRLF)
        Return
    EndIf

    ; Read the contents of the chunk file
    Local $fileContents = FileRead($fullPath)

    ; Build the search pattern for the X and Y coordinates
    Local $coordinatePattern = '"X' & $x & 'Y' & $y & '": "solid"'

    ; Replace "solid" with the desired status
    $fileContents = StringReplace($fileContents, $coordinatePattern, '"X' & $x & 'Y' & $y & '": "' & $status & '"')

    ; Write the updated content back to the file
    FileDelete($fullPath) ; Delete the old file
    FileWrite($fullPath, $fileContents)
EndFunc

; Function to retrieve the passability status of a coordinate
Func GetCoordinateStatus($x, $y)
    Local $xChunk = Floor($x / $ChunkSize)
    Local $yChunk = Floor($y / $ChunkSize)
    Local $chunkFileName = "coordinates_" & $xChunk & "_" & $yChunk & ".json"
    Local $fullPath = $CoordinateDir & $chunkFileName

    If Not FileExists($fullPath) Then
        ConsoleWrite("Error: Chunk file not found." & @CRLF)
        Return "solid" ; Default to solid if the file doesn't exist
    EndIf

    Local $fileContents = FileRead($fullPath)
    Local $coordinateKey = '"X' & $x & 'Y' & $y & '"'

    If StringInStr($fileContents, $coordinateKey) Then
        ; Parse to find the status
        Local $status = StringMid($fileContents, StringInStr($fileContents, $coordinateKey) + StringLen($coordinateKey) + 4, 6)
        Return StringStripWS($status, 0) ; Remove any surrounding whitespace
    EndIf

    Return "solid" ; Default to solid if not found
EndFunc
