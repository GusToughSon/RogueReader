#include <Array.au3>
#include <Misc.au3>

; Function to open the memory of the specified process using DllCall
Func _MemoryOpen($ProcessID)
    Local $hProcess = DllCall("kernel32.dll", "ptr", "OpenProcess", "int", 0x1F0FFF, "bool", False, "dword", $ProcessID)
    If @error Or Not IsPtr($hProcess[0]) Then
        MsgBox(0, "Error", "Failed to open memory for the process.")
        Return 0 ; Return 0 if the process could not be opened
    EndIf
    Return $hProcess[0] ; Return the handle of the process
EndFunc

; Function to close the memory handle
Func _MemoryClose($hProcess)
    DllCall("kernel32.dll", "int", "CloseHandle", "ptr", $hProcess)
EndFunc

; Function to read memory
Func _MemoryRead($address, $hProcess, $type)
    Local $data
    If $type = "dword" Then
        Local $ptr = DllStructCreate("dword")
        DllCall("kernel32.dll", "int", "ReadProcessMemory", "ptr", $hProcess, "ptr", $address, "ptr", DllStructGetPtr($ptr), "ptr", 4)
        $data = DllStructGetData($ptr, 1)
    EndIf
    Return $data ; Return the data read
EndFunc

; Function to get the base address using EnumProcessModules
Func _EnumProcessModules($hProcess)
    Local $hMod = DllStructCreate("ptr") ; 64-bit pointer
    Local $moduleSize = DllStructGetSize($hMod)

    ; Call EnumProcessModules to list modules
    Local $aModules = DllCall("psapi.dll", "int", "EnumProcessModulesEx", "ptr", $hProcess, "ptr", DllStructGetPtr($hMod), "dword", $moduleSize, "dword*", 0, "dword", 0x03)

    If IsArray($aModules) And $aModules[0] <> 0 Then
        Return DllStructGetData($hMod, 1) ; Return base address
    Else
        Return 0
    EndIf
EndFunc
