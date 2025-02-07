#AutoIt3Wrapper_CompileX86=y          ; Tells AutoIt to compile as 32-bit if you compile it.
#AutoIt3Wrapper_Change2CUI=y          ; Console app mode, so logs show in SciTE console
#include <NomadMemory.au3>

; Press ESC to exit quickly
HotKeySet("{ESC}", "_ExitScript")

ConsoleWrite("[DEBUG] Script started." & @CRLF)
ConsoleWrite("[DEBUG] @OSArch = " & @OSArch & " (Will attempt memory operations regardless.)" & @CRLF)
ConsoleWrite("[DEBUG] IsAdmin() = " & IsAdmin() & " (1 means running as Admin)" & @CRLF)

; ---------------------------------------------------------------------------
; Setup
; ---------------------------------------------------------------------------
Global $ProcessName     = "Project Rogue Client.exe"
Global $Offset_ChatOpen = 0x9B7A18  ; Memory offset for 'chat open' (0 or 1)
Global $PID = ProcessExists($ProcessName)

ConsoleWrite("[DEBUG] Attempting to find process: " & $ProcessName & @CRLF)
If Not $PID Then
    ConsoleWrite("[ERROR] Process not found. Exiting." & @CRLF)
    Exit
EndIf

ConsoleWrite("[DEBUG] Found process '" & $ProcessName & "' with PID=" & $PID & @CRLF)

; ---------------------------------------------------------------------------
; Open the process
; ---------------------------------------------------------------------------
Global $hProcess = _MemoryOpen($PID)
ConsoleWrite("[DEBUG] _MemoryOpen() returned handle=0x" & Hex($hProcess) & @CRLF)

If $hProcess = 0 Or @error Then
    ConsoleWrite("[ERROR] _MemoryOpen() gave a 0 handle or an error. Likely can't read memory." & @CRLF & _
        "        (Either permissions, mismatched bitness, or the module doesn't allow it.)" & @CRLF)
Else
    ConsoleWrite("[DEBUG] _MemoryOpen() handle appears nonzero. Attempting to read memory." & @CRLF)
EndIf

; ---------------------------------------------------------------------------
; Attempt to get the module base
; ---------------------------------------------------------------------------
ConsoleWrite("[DEBUG] Attempting to get base address for module: " & $ProcessName & @CRLF)
Global $ModuleBase = _MemoryModuleGetBaseAddress($ProcessName, $ProcessName)

If $ModuleBase = 0 Then
    ConsoleWrite("[ERROR] _MemoryModuleGetBaseAddress() returned 0. Cannot find module." & @CRLF & _
        "        (Possible mismatch in bitness, wrong module name, or permissions.)" & @CRLF)
Else
    ConsoleWrite("[DEBUG] ModuleBase=0x" & Hex($ModuleBase) & @CRLF)
EndIf

; Calculate the final address
Global $ChatAddress = $ModuleBase + $Offset_ChatOpen
ConsoleWrite("[DEBUG] Final chat address=0x" & Hex($ChatAddress) & @CRLF)

; ---------------------------------------------------------------------------
; Main loop
; ---------------------------------------------------------------------------
ConsoleWrite("[DEBUG] Entering main loop. Press ESC to exit." & @CRLF)
While True
    ; Attempt to read the chat value
    Local $readData = _MemoryRead($ChatAddress, $hProcess, "byte")
    If Not IsArray($readData) Then
        ConsoleWrite("[ERROR] _MemoryRead returned a non-array. Memory read likely failed." & @CRLF)
    Else
        Local $chatVal = $readData[1]
        ConsoleWrite("[DEBUG] Chat open value = " & $chatVal & @CRLF)
    EndIf

    Sleep(1000)
WEnd

Func _ExitScript()
    ConsoleWrite("[DEBUG] ESC pressed. Closing handle (if any) and exiting." & @CRLF)
    If $hProcess <> 0 Then _MemoryClose($hProcess)
    Exit
EndFunc
