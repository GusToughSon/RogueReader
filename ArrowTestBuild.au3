; === Arrow keys to WASD remapper with smooth diagonals ===

Global $ProcessName = "Project Rogue Client.exe"
Global $WindowName = "Project Rogue"

; Track which WASD keys are currently held
Global $keysHeld = ["", "", "", ""] ; W, A, S, D

HotKeySet("{UP}", "_ArrowDown", "w")
HotKeySet("{DOWN}", "_ArrowDown", "s")
HotKeySet("{LEFT}", "_ArrowDown", "a")
HotKeySet("{RIGHT}", "_ArrowDown", "d")
HotKeySet("{UP UP}", "_ArrowUp", "w")
HotKeySet("{DOWN UP}", "_ArrowUp", "s")
HotKeySet("{LEFT UP}", "_ArrowUp", "a")
HotKeySet("{RIGHT UP}", "_ArrowUp", "d")

ConsoleWrite("[INFO] Smooth Arrow→WASD remapper started." & @CRLF)

Func _ArrowDown($key)
    If _AddKey($key) Then
        ConsoleWrite("[HOLD] Pressing key: " & $key & @CRLF)
        _KeyDown($key)
    EndIf
EndFunc

Func _ArrowUp($key)
    If _RemoveKey($key) Then
        ConsoleWrite("[RELEASE] Releasing key: " & $key & @CRLF)
        _KeyUp($key)
    EndIf
EndFunc

Func _AddKey($key)
    For $i = 0 To UBound($keysHeld) - 1
        If $keysHeld[$i] = $key Then Return False ; Already held
        If $keysHeld[$i] = "" Then
            $keysHeld[$i] = $key
            Return True
        EndIf
    Next
    Return False ; No empty slot
EndFunc

Func _RemoveKey($key)
    For $i = 0 To UBound($keysHeld) - 1
        If $keysHeld[$i] = $key Then
            $keysHeld[$i] = ""
            Return True
        EndIf
    Next
    Return False ; Not held
EndFunc

Func _KeyDown($key)
    Local $hwnd = WinGetHandle($WindowName)
    If @error Or $hwnd = 0 Then
        ConsoleWrite("[ERROR] Window not found: " & $WindowName & @CRLF)
        Return
    EndIf
    ControlSend($WindowName, "", "", "{" & $key & " down}")
EndFunc

Func _KeyUp($key)
    Local $hwnd = WinGetHandle($WindowName)
    If @error Or $hwnd = 0 Then
        ConsoleWrite("[ERROR] Window not found: " & $WindowName & @CRLF)
        Return
    EndIf
    ControlSend($WindowName, "", "", "{" & $key & " up}")
EndFunc

While 1
    Sleep(20) ; Smoother polling
WEnd
