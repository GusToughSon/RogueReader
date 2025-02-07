#include <WinAPI.au3>
#include <Process.au3>

Global $sProcessName = "Project Rogue Client.exe"
Global $iOffset = 0x9B7A18  ; The memory offset to read from

ConsoleWrite("[INFO] Searching for process: " & $sProcessName & @CRLF)

; Get Process ID
Local $aProcessList = ProcessList($sProcessName)
If $aProcessList[0][0] = 0 Then
    ConsoleWrite("[ERROR] Process not found!" & @CRLF)
    Exit
EndIf

Local $iPID = $aProcessList[1][1]
ConsoleWrite("[INFO] Process ID: " & $iPID & @CRLF)

; Open Process Handle
Local $hProcess = _WinAPI_OpenProcess(0x1F0FFF, False, $iPID) ; Full access rights
If $hProcess = 0 Then
    ConsoleWrite("[ERROR] Failed to open process! Try running as administrator." & @CRLF)
    Exit
EndIf

; Get the base address using EnumProcessModules (WORKING METHOD)
Local $hBaseAddress = _GetModuleBase_EnumModules($hProcess)
If $hBaseAddress = 0 Then
    ConsoleWrite("[ERROR] Failed to obtain a valid base address!" & @CRLF)
    Exit
EndIf

ConsoleWrite("[INFO] Base Address: 0x" & Hex($hBaseAddress) & @CRLF)

; Calculate the final memory address
Local $pMemoryAddress = $hBaseAddress + $iOffset
ConsoleWrite("[INFO] Final Memory Address: 0x" & Hex($pMemoryAddress) & @CRLF)

; Read memory at calculated address
Local $iValue = _ReadMemory($hProcess, $pMemoryAddress)
ConsoleWrite("[SUCCESS] Value at " & $sProcessName & "+" & Hex($iOffset) & ": " & $iValue & @CRLF)

; Close process handle
_WinAPI_CloseHandle($hProcess)
Exit


; ####################### METHOD: EnumProcessModules (WORKING METHOD) ########################
Func _GetModuleBase_EnumModules($hProcess)
    Local $hPsapi = DllOpen("psapi.dll")
    If $hPsapi = 0 Then Return 0

    Local $aModules = DllStructCreate("ptr[1024]")
    Local $aBytesNeeded = DllStructCreate("dword")

    Local $aCall = DllCall($hPsapi, "bool", "EnumProcessModules", "handle", $hProcess, "ptr", DllStructGetPtr($aModules), "dword", DllStructGetSize($aModules), "ptr", DllStructGetPtr($aBytesNeeded))
    If @error Or Not $aCall[0] Then Return 0

    Local $pBaseAddress = DllStructGetData($aModules, 1, 1)
    DllClose($hPsapi)
    Return $pBaseAddress
EndFunc


; ####################### FUNCTION TO READ MEMORY ########################
Func _ReadMemory($hProcess, $pAddress)
    Local $tBuffer = DllStructCreate("dword")  ; Change type if needed
    Local $aRead = DllCall("kernel32.dll", "bool", "ReadProcessMemory", "handle", $hProcess, "ptr", $pAddress, "ptr", DllStructGetPtr($tBuffer), "dword", DllStructGetSize($tBuffer), "ptr", 0)

    If @error Or Not $aRead[0] Then
        ConsoleWrite("[ERROR] Failed to read memory!" & @CRLF)
        Return -1
    EndIf

    Return DllStructGetData($tBuffer, 1)
EndFunc
