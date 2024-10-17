; GUI Creation - Moved to Gui.au3
Func CreateGUI()
    Global $Gui, $TypeLabel, $AttackModeLabel, $PosXLabel, $PosYLabel, $HPLabel, $MaxHPLabel, $ChatStatusLabel, $AilmentLabel
    Global $HealerLabel, $HotkeyLabel, $ChangeHotkeyButton, $SliderLabel, $Slider, $RefreshSlider, $RefreshLabel, $DebugButton, $DebugLabel, $KillButton, $ExitButton

    ; Adjusted the size and layout of the GUI
    $Gui = GUICreate("RogueReader", 500, 600, 15, 15) ; Resize window to make room for all controls

    ; Create the labels
    $TypeLabel = GUICtrlCreateLabel("Type: N/A", 20, 30, 250, 20)
    $AttackModeLabel = GUICtrlCreateLabel("Attack Mode: N/A", 20, 60, 250, 20)
    $PosXLabel = GUICtrlCreateLabel("Pos X: N/A", 20, 90, 250, 20)
    $PosYLabel = GUICtrlCreateLabel("Pos Y: N/A", 20, 120, 250, 20)
    $HPLabel = GUICtrlCreateLabel("HP: N/A", 20, 150, 250, 20)
    $MaxHPLabel = GUICtrlCreateLabel("MaxHP: N/A", 20, 180, 250, 20)
    $ChatStatusLabel = GUICtrlCreateLabel("Chat: N/A", 20, 210, 250, 20)
    $AilmentLabel = GUICtrlCreateLabel("Ailment: N/A", 20, 240, 250, 20)
    $HealerLabel = GUICtrlCreateLabel("Healer: OFF", 20, 270, 250, 20)
    $HotkeyLabel = GUICtrlCreateLabel("Healer Hotkey: N/A", 20, 300, 250, 20)

    ; Button to change the healer hotkey
    $ChangeHotkeyButton = GUICtrlCreateButton("Change Healer Hotkey", 280, 300, 150, 30)

    ; Slider for dynamic healing percentage
    $SliderLabel = GUICtrlCreateLabel("Heal if HP below: 95%", 20, 340, 250, 20)
    $Slider = GUICtrlCreateSlider(20, 370, 200, 30)
    GUICtrlSetLimit($Slider, 100, 50)
    GUICtrlSetData($Slider, 95)

    ; Slider for refresh rate (50ms to 150ms)
    $RefreshLabel = GUICtrlCreateLabel("Refresh Rate: 50ms", 20, 420, 250, 20)
    $RefreshSlider = GUICtrlCreateSlider(20, 450, 200, 30)
    GUICtrlSetLimit($RefreshSlider, 150, 50)
    GUICtrlSetData($RefreshSlider, 50)

    ; Buttons to close Rogue and Exit
    $KillButton = GUICtrlCreateButton("Kill Rogue", 20, 500, 100, 30)
    $ExitButton = GUICtrlCreateButton("Exit", 150, 500, 100, 30)

    ; Button and Label to toggle debug mode
    $DebugButton = GUICtrlCreateButton("Toggle Debug", 280, 500, 150, 30)
    $DebugLabel = GUICtrlCreateLabel("Debug: OFF", 20, 550, 250, 20)

    GUISetState(@SW_SHOW)
EndFunc

; Function to update the healer hotkey label
Func UpdateHealerHotkeyLabel($HealerHotkey)
    GUICtrlSetData($HotkeyLabel, "Healer Hotkey: " & $HealerHotkey)
EndFunc

; Function to update the GUI with memory values
Func UpdateGUI($Type, $AttackMode, $PosX, $PosY, $HP, $MaxHP, $ChatStatus, $Ailment)
    ; Update Type label
    If $Type = 0 Or $Type = 65535 Then
        GUICtrlSetData($TypeLabel, "Type: None")
    ElseIf $Type = 1 Then
        GUICtrlSetData($TypeLabel, "Type: Monster")
    ElseIf $Type = 2 Then
        GUICtrlSetData($TypeLabel, "Type: NPC")
    ElseIf $Type = 3 Then
        GUICtrlSetData($TypeLabel, "Type: Player")
    Else
        GUICtrlSetData($TypeLabel, "Type: Unknown (" & $Type & ")")
    EndIf

    ; Update Attack Mode label
    If $AttackMode = 0 Then
        GUICtrlSetData($AttackModeLabel, "Attack Mode: Safe")
    ElseIf $AttackMode = 1 Then
        GUICtrlSetData($AttackModeLabel, "Attack Mode: Attack")
    Else
        GUICtrlSetData($AttackModeLabel, "Attack Mode: Unknown")
    EndIf

    ; Update Position, HP, MaxHP, and Chat Status
    GUICtrlSetData($PosXLabel, "Pos X: " & $PosX)
    GUICtrlSetData($PosYLabel, "Pos Y: " & $PosY)
    GUICtrlSetData($HPLabel, "HP: " & $HP)
    GUICtrlSetData($MaxHPLabel, "MaxHP: " & $MaxHP)

    If $ChatStatus = 0 Then
        GUICtrlSetData($ChatStatusLabel, "Chat: Closed")
    Else
        GUICtrlSetData($ChatStatusLabel, "Chat: Open")
    EndIf

    ; Update Ailment label
    If $Ailment = 0 Then
        GUICtrlSetData($AilmentLabel, "Ailment: None")
    ElseIf $Ailment = 1 Then
        GUICtrlSetData($AilmentLabel, "Ailment: Poisoned")
    ElseIf $Ailment = 2 Then
        GUICtrlSetData($AilmentLabel, "Ailment: Diseased")
    Else
        GUICtrlSetData($AilmentLabel, "Ailment: Unknown (" & $Ailment & ")")
    EndIf
EndFunc
