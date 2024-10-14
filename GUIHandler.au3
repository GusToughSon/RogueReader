#include <GUIConstantsEx.au3>

; Function to create the GUI
Func CreateMainGUI()
    Local $Gui = GUICreate("RogueReader", 450, 500, 15, 15) ; Width = 450, Height = 500, X = 15, Y = 15
    GUICtrlCreateLabel("Type: N/A", 20, 30, 250, 20)
    GUICtrlCreateLabel("Attack Mode: N/A", 20, 60, 250, 20)
    GUICtrlCreateLabel("Pos X: N/A", 20, 90, 250, 20)
    GUICtrlCreateLabel("Pos Y: N/A", 20, 120, 250, 20)
    GUICtrlCreateLabel("HP: N/A", 20, 150, 250, 20)
    GUICtrlCreateLabel("HP2: N/A", 20, 180, 250, 20)
    GUICtrlCreateLabel("MaxHP: N/A", 20, 210, 250, 20)
    Global $HealerLabel = GUICtrlCreateLabel("Healer: OFF", 20, 240, 250, 20) ; Declare globally
    Global $LoggingStatusLabel = GUICtrlCreateLabel("Logging: Off", 20, 340, 250, 20) ; Declare globally
    Global $MapLogButton = GUICtrlCreateButton("Toggle Map Logging", 20, 380, 150, 30) ; Declare globally
    Global $KillButton = GUICtrlCreateButton("Kill Rogue", 190, 380, 100, 30) ; Declare globally
    Global $ExitButton = GUICtrlCreateButton("Exit", 300, 380, 100, 30) ; Declare globally

    GUISetState(@SW_SHOW)
    Return $Gui
EndFunc
