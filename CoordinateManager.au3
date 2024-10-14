#include <Array.au3>

Global $MaxCoordinate = 7000
Global $ChunkSize = 1000 ; Each chunk will now have 1000 x 1000 coordinates
Global $CoordinateDir = @ScriptDir & "\coordinates\" ; Directory for storing the coordinate chunks

; Initialize coordinate files in binary format
Func InitializeBinaryCoordinateFiles()
    ConsoleWrite("Initializing binary coordinate files..." & @CRLF)

    ; Create the coordinate directory if it doesn't exist
    If Not FileExists($CoordinateDir) Then
        DirCreate($CoordinateDir)
    EndIf

    ; Loop through X and Y chunks to create binary files
    For $xChunk = 0 To Floor($MaxCoordinate / $ChunkSize)
        For $yChunk = 0 To Floor($MaxCoordinate / $ChunkSize)
            Local $fileName = "coordinates_" & $xChunk & "_" & $yChunk & ".bin"
            Local $fullPath = $CoordinateDir & $fileName

            ; Check if the binary file already exists
            If Not FileExists($fullPath) Then
                ConsoleWrite("Creating binary chunk file: " & $fullPath & @CRLF)
                InitializeBinaryChunkFile($fullPath)
            EndIf
        Next
    Next

    ConsoleWrite("All binary chunk files created." & @CRLF)
EndFunc

; Function to initialize a specific binary chunk file
Func InitializeBinaryChunkFile($fullPath)
    Local $fileHandle = FileOpen($fullPath, 18) ; Binary write mode
    If $fileHandle = -1 Then
        MsgBox(0, "Error", "Failed to create the chunk file.")
        Exit
    EndIf

    ; Loop through each coordinate in the chunk and write its status as "solid" (0)
    For $i = 0 To ($ChunkSize * $ChunkSize) - 1
        FileWrite($fileHandle, Binary("0x00")) ; Writing solid (0) as the default
    Next

    FileClose($fileHandle)
EndFunc

; Function to update the status of a specific coordinate in a binary chunk file
Func UpdateBinaryCoordinate($x, $y, $status = "passable")
    Local $xChunk = Floor($x / $ChunkSize)
    Local $yChunk = Floor($y / $ChunkSize)
    Local $chunkFileName = "coordinates_" & $xChunk & "_" & $yChunk & ".bin"
    Local $fullPath = $CoordinateDir & $chunkFileName

    ; Ensure the binary file exists
    If Not FileExists($fullPath) Then
        ConsoleWrite("Error: Binary chunk file not found." & @CRLF)
        Return
    EndIf

    ; Calculate the index within the binary file
    Local $localX = Mod($x, $ChunkSize)
    Local $localY = Mod($y, $ChunkSize)
    Local $index = ($localY * $ChunkSize) + $localX

    ; Open the binary file for update
    Local $fileHandle = FileOpen($fullPath, 26) ; Binary read/write mode
    FileSetPos($fileHandle, $index, 0) ; Seek to the correct byte (mode 0 for absolute position)

    ; Write the status: 0x01 for passable, 0x00 for solid
    If $status = "passable" Then
        FileWrite($fileHandle, Binary("0x01"))
    Else
        FileWrite($fileHandle, Binary("0x00"))
    EndIf

    FileClose($fileHandle)
EndFunc

; Function to retrieve the passability status of a coordinate from binary file
Func GetCoordinateStatusFromBinary($x, $y)
    Local $xChunk = Floor($x / $ChunkSize)
    Local $yChunk = Floor($y / $ChunkSize)
    Local $chunkFileName = "coordinates_" & $xChunk & "_" & $yChunk & ".bin"
    Local $fullPath = $CoordinateDir & $chunkFileName

    ; Ensure the binary file exists
    If Not FileExists($fullPath) Then
        ConsoleWrite("Error: Binary chunk file not found." & @CRLF)
        Return "solid" ; Default to solid if the file doesn't exist
    EndIf

    ; Calculate the index within the binary file
    Local $localX = Mod($x, $ChunkSize)
    Local $localY = Mod($y, $ChunkSize)
    Local $index = ($localY * $ChunkSize) + $localX

    ; Read the specific byte from the file
    Local $fileHandle = FileOpen($fullPath, 16) ; Binary read mode
    FileSetPos($fileHandle, $index, 0) ; Seek to the correct byte (mode 0 for absolute position)
    Local $status = FileRead($fileHandle, 1) ; Read 1 byte
    FileClose($fileHandle)

    ; Return "passable" for 1, "solid" for 0
    If Binary($status) = Binary("0x01") Then
        Return "passable"
    Else
        Return "solid"
    EndIf
EndFunc
