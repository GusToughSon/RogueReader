#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>

Global $WindowName1 = "Project Rogue Unique 1"
Global $WindowName2 = "Project Rogue Unique 2"
Global $ActiveWindow = $WindowName1  ; Default to Window 1

; Create GUI
$hGUI = GUICreate("Window Control", 200, 100)
$btnWindow1 = GUICtrlCreateButton("Window 1", 10, 10, 180, 30)
$btnWindow2 = GUICtrlCreateButton("Window 2", 10, 50, 180, 30)

GUISetState(@SW_SHOW, $hGUI)

; Event loop
While 1
    Switch GUIGetMsg()
        Case $GUI_EVENT_CLOSE
            Exit
        Case $btnWindow1
            SelectWindow(1)
        Case $btnWindow2
            SelectWindow(2)
    EndSwitch
WEnd

Func SelectWindow($iWindow)
    Switch $iWindow
        Case 1
            $ActiveWindow = $WindowName1
            ConsoleWrite("Active window set to Window 1: " & $ActiveWindow & @CRLF)
        Case 2
            $ActiveWindow = $WindowName2
            ConsoleWrite("Active window set to Window 2: " & $ActiveWindow & @CRLF)
    EndSwitch
EndFunc
