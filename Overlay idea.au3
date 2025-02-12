#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <WinAPI.au3>
#include <StaticConstants.au3>

Opt("GUIOnEventMode", 1)

Global $gameTitle = "Project Rogue"
Global $gameWindow = WinGetHandle($gameTitle)

; Check if game window is found
If @error Then
    ConsoleWrite("Error: Game window '" & $gameTitle & "' not found." & @CRLF)
    Exit
Else
    ConsoleWrite("Game window '" & $gameTitle & "' found." & @CRLF)
EndIf

; Create a semi-transparent GUI
$overlayGUI = GUICreate("Game Overlay", 200, 50, 0, 0, $WS_POPUP, $WS_EX_TOPMOST + $WS_EX_LAYERED)
GUISetBkColor(0xABCDEF) ; Arbitrary color for background
WinSetTrans($overlayGUI, "", 150) ; Semi-transparent background

; Create a green dot
$ellipse = GUICtrlCreateGraphic(10, 10, 30, 30)
GUICtrlSetGraphic(-1, $GUI_GR_ELLIPSE, 5, 5, 20, 20)
GUICtrlSetBkColor(-1, 0x00FF00) ; Green color

; Create a label with text
$label = GUICtrlCreateLabel("Test", 40, 15, 50, 20)
GUICtrlSetColor($label, 0xFFFFFF) ; White text

; Register close function
GUISetOnEvent($GUI_EVENT_CLOSE, "CloseOverlay")

; Adjust overlay based on game window
AdaptOverlay()

; Show the GUI
GUISetState(@SW_SHOW, $overlayGUI)

While 1
    Sleep(100)
    AdaptOverlay()
WEnd

Func AdaptOverlay()
    Local $pos = WinGetPos($gameWindow)
    If Not @error Then
        ConsoleWrite("Updating overlay position to top: " & $pos[1] & " left: " & $pos[0] & " width: " & $pos[2] & " height: " & $pos[3] & @CRLF)
        WinMove($overlayGUI, "", $pos[0] + $pos[2] - 200, $pos[1] + $pos[3] - 50, 200, 50)
    Else
        ConsoleWrite("Error: Unable to get game window position." & @CRLF)
    EndIf
EndFunc

Func CloseOverlay()
    ; Clean up and exit
    ConsoleWrite("Closing overlay." & @CRLF)
    Exit
EndFunc
