Opt("MouseCoordMode", 1) ; 1 = absolute screen coords
#include <MsgBoxConstants.au3>
#include <File.au3>

; ------------------------------------------------------------------------------
; CONFIGURATION
; ------------------------------------------------------------------------------
Global $g_sPickupDir    = @ScriptDir & "\PickupItems"
Global $g_sGoldFile     = $g_sPickupDir & "\gold.png"
Global $g_sWindowName   = "Project Rogue"

; The absolute-screen region we scan:
Global $g_iX1 = 300, $g_iY1 = 300
Global $g_iX2 = 400, $g_iY2 = 400

; "Gold" reference color
Global $g_iTargetColor = 0xFFD700
Global $g_iTolerance   = 15

; Whether we log EVERY pixel color in the region. This can produce a lot of output.
Global $g_bLogAllColors = True

; ------------------------------------------------------------------------------
; MAIN
; ------------------------------------------------------------------------------
_Main()

Func _Main()
    ConsoleWrite("=== Starting 'Brute-Force Gold Finder' Script ===" & @CRLF)

    ; 1) Check gold.png in PickupItems
    If Not FileExists($g_sGoldFile) Then
        ConsoleWrite("ERROR: " & $g_sGoldFile & " not found in PickupItems." & @CRLF)
        MsgBox($MB_TOPMOST, "Error", "'gold.png' not found in 'PickupItems' folder.")
        Return
    EndIf
    ConsoleWrite("Confirmed 'gold.png' is present: " & $g_sGoldFile & @CRLF)

    ; 2) Wait for Project Rogue window
    ConsoleWrite("Waiting for window '" & $g_sWindowName & "'..." & @CRLF)
    If Not WinWait($g_sWindowName, "", 10) Then
        ConsoleWrite("ERROR: Window '" & $g_sWindowName & "' not found or not active within 10 seconds." & @CRLF)
        MsgBox($MB_TOPMOST, "Error", "'" & $g_sWindowName & "' not found.")
        Return
    EndIf
    ConsoleWrite("Window '" & $g_sWindowName & "' found. Activating..." & @CRLF)
    WinActivate($g_sWindowName)
    Sleep(250) ; short pause to ensure it is really on top

    ; 3) Enumerate EVERY pixel in (300,300)->(400,400)
    ConsoleWrite("Enumerating region (" & $g_iX1 & "," & $g_iY1 & ") -> (" & $g_iX2 & "," & $g_iY2 & ")..." & @CRLF)
    Local $bFound = False
    For $y = $g_iY1 To $g_iY2
        For $x = $g_iX1 To $g_iX2
            Local $clr = PixelGetColor($x, $y)
            If $g_bLogAllColors Then
                ConsoleWrite("  At [" & $x & "," & $y & "] color=0x" & Hex($clr, 6) & @CRLF)
            EndIf

            ; 4) Check if color is "close" to 0xFFD700 within tolerance
            If _ColorWithinTolerance($clr, $g_iTargetColor, $g_iTolerance) Then
                ConsoleWrite("MATCH near 0x" & Hex($g_iTargetColor, 6) & " found at [" & $x & "," & $y & "]." & @CRLF)
                MouseClick("right", $x, $y, 1, 0)
                $bFound = True
                ExitLoop ; exit the X loop
            EndIf
        Next

        If $bFound Then ExitLoop ; exit the Y loop
    Next

    If Not $bFound Then
        ConsoleWrite("NO pixel in that region is within " & $g_iTolerance & _
                     " of 0x" & Hex($g_iTargetColor, 6) & ". No click performed." & @CRLF)
    EndIf

    ConsoleWrite("=== Script Finished ===" & @CRLF)
EndFunc

; ------------------------------------------------------------------------------
; HELPER: Check if two colors are within a certain tolerance
; ------------------------------------------------------------------------------
Func _ColorWithinTolerance($clr1, $clr2, $tol)
    ; Extract R,G,B from each color
    Local $r1 = BitShift(BitAND($clr1, 0xFF0000), -16)
    Local $g1 = BitShift(BitAND($clr1, 0x00FF00), -8)
    Local $b1 = BitAND($clr1, 0x0000FF)

    Local $r2 = BitShift(BitAND($clr2, 0xFF0000), -16)
    Local $g2 = BitShift(BitAND($clr2, 0x00FF00), -8)
    Local $b2 = BitAND($clr2, 0x0000FF)

    ; Compare each channel difference to the tolerance
    If Abs($r1 - $r2) <= $tol And _
       Abs($g1 - $g2) <= $tol And _
       Abs($b1 - $b2) <= $tol Then
        Return True
    EndIf
    Return False
EndFunc
