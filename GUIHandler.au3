#include <GUIConstantsEx.au3>

; Declare GUI control variables globally
Global $HealerLabel, $LoggingStatusLabel, $MapLogButton, $ExitButton, $KillButton

; Function to create the GUI
Func CreateMainGUI()
    Local $Gui = GUICreate("RogueReader", 450, 500, 15, 15) ; Width = 450, Height = 500, X = 15, Y = 15
    $HealerLabel = GUICtrlCreateLabel("Healer: OFF", 20, 240, 250, 20)
    $LoggingStatusLabel = GUICtrlCreateLabel("Logging: Off", 20, 340, 250, 20)
    $MapLogButton = GUICtrlCreateButton("Toggle Map Logging", 20, 380, 150, 30)
    $KillButton = GUICtrlCreateButton("Kill Rogue", 190, 380, 100, 30) ; Add the Kill Rogue button
    $ExitButton = GUICtrlCreateButton("Exit", 300, 380, 100, 30)

    GUICtrlCreateLabel("Type: N/A", 20, 30, 250, 20)
    GUICtrlCreateLabel("Attack Mode: N/A", 20, 60, 250, 20)
    GUICtrlCreateLabel("Pos X: N/A", 20, 90, 250, 20)
    GUICtrlCreateLabel("Pos Y: N/A", 20, 120, 250, 20)
    GUICtrlCreateLabel("HP: N/A", 20, 150, 250, 20)
    GUICtrlCreateLabel("HP2: N/A", 20, 180, 250, 20)
    GUICtrlCreateLabel("MaxHP: N/A", 20, 210, 250, 20)
    GUICtrlCreateLabel("Hotkey: ", 20, 270, 250, 20)
    GUICtrlCreateLabel("Pots go in #2", 20, 300, 250, 20)

    GUISetState(@SW_SHOW)
    Return $Gui
EndFunc
