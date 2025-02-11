#include <WinAPIProc.au3>
#include <MsgBoxConstants.au3>
#include <File.au3>

Global $debugMode = True  ; Set this to True to enable debug mode, False to disable

; Define the window title
$windowTitle = "Project Rogue"

; Attempt to get the handle of the window
$windowHandle = WinGetHandle($windowTitle)
DebugPrint("Window Handle: " & $windowHandle)

If $windowHandle <> 0 Then
    DebugPrint("Window found, getting process ID...")
    ; Window found, now get the process ID
    $processID = WinGetProcess($windowHandle)
    DebugPrint("Process ID: " & $processID)

    If $processID <> 0 Then
        DebugPrint("Process ID found, getting process path...")
        ; Process ID found, now get the process path
        $processPath = _WinAPI_GetProcessFileName($processID)

        If @error Then
            DebugPrint("Error: Failed to retrieve process path.")
        Else
            DebugPrint("Process Path: " & $processPath)
            ; Calculate directory path by finding the last backslash
            $lastBackslashPos = StringInStr($processPath, "\", 0, -1)  ; Search from end of string
            $directoryPath = StringLeft($processPath, $lastBackslashPos - 1)
            $jsonFilePath = $directoryPath & "\Settings.json"
            DebugPrint("Checking for Settings.json at: " & $jsonFilePath)

            If FileExists($jsonFilePath) Then
                DebugPrint("Settings.json found, extracting values...")
                ; Read the file content
                $fileContent = FileRead($jsonFilePath)

                ; Extract variables
                $message = "Backpack X: " & ExtractValue($fileContent, '"Backpack":', '"X":') & @CRLF
                $message &= "Backpack Y: " & ExtractValue($fileContent, '"Backpack":', '"Y":') & @CRLF
                $message &= "Bank X: " & ExtractValue($fileContent, '"Bank":', '"X":') & @CRLF
                $message &= "Bank Y: " & ExtractValue($fileContent, '"Bank":', '"Y":') & @CRLF
                $message &= "Corpse X: " & ExtractValue($fileContent, '"Corpse":', '"X":') & @CRLF
                $message &= "Corpse Y: " & ExtractValue($fileContent, '"Corpse":', '"Y":') & @CRLF
                $message &= "Minimap X: " & ExtractValue($fileContent, '"Minimap":', '"X":') & @CRLF
                $message &= "Minimap Y: " & ExtractValue($fileContent, '"Minimap":', '"Y":')

                ; Display the message box with the extracted variables
                MsgBox($MB_SYSTEMMODAL, "Extracted Settings", $message)
            Else
                DebugPrint("Error: Settings.json file not found.")
            EndIf
        EndIf
    Else
        DebugPrint("Error: Failed to retrieve process ID.")
    EndIf
Else
    DebugPrint("Error: Window not found.")
EndIf

Func DebugPrint($message)
    If $debugMode Then
        ConsoleWrite($message & @CRLF)  ; Output the message to the console if debug mode is on
    EndIf
EndFunc

Func ExtractValue($content, $section, $key)
    Local $start = StringInStr($content, $section)
    Local $keyPos = StringInStr($content, $key, 0, 1, $start)
    Local $startValue = $keyPos + StringLen($key)
    Local $endValue = StringInStr($content, ',', 0, 1, $startValue)
    If $endValue = 0 Then
        $endValue = StringInStr($content, '}', 0, 1, $startValue)
    EndIf
    Local $extractedValue = StringMid($content, $startValue, $endValue - $startValue)
    $extractedValue = StringRegExpReplace($extractedValue, "[^\d]", "")
    Return $extractedValue
EndFunc
