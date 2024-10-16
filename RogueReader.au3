#include "NomadMemory.au3"
#include <GUIConstantsEx.au3>
#include <Misc.au3>
#include <File.au3>

Global $pottimer = 2000
Global $DebugMode = False ; Debug mode is now set to False by default
Global $configFile = @ScriptDir & "\config.ini" ; Path to the config file
Global $HealerStatus = False
Global $HealerHotkey = "`" ; Default hotkey for healer
Global $RefreshRate = 50 ; Default refresh rate (50ms)

; Check if the config file exists, if not, create it and set default slider value to 95 and refresh rate to 50ms
If Not FileExists($configFile) Then
    IniWrite($configFile, "Settings", "HealPercentage", "95")
    IniWrite($configFile, "Settings", "HealerHotkey", $HealerHotkey)
    IniWrite($configFile, "Settings", "RefreshRate", "50")
EndIf

; Read the slider value, hotkey, and refresh rate from the config file
$SliderValue = IniRead($configFile, "Settings", "HealPercentage", "95")
$HealerHotkey = IniRead($configFile, "Settings", "HealerHotkey", "`")
$RefreshRate = IniRead($configFile, "Settings", "RefreshRate", "50")

; Register the hotkey for healer
HotKeySet($HealerHotkey, "ToggleHealer")

; Create the GUI
$Gui = GUICreate("RogueReader", 450, 600, 15, 15)
$TypeLabel = GUICtrlCreateLabel("Type: N/A", 20, 30, 250, 20)
$AttackModeLabel = GUICtrlCreateLabel("Attack Mode: N/A", 20, 60, 250, 20)
$PosXLabel = GUICtrlCreateLabel("Pos X: N/A", 20, 90, 250, 20)
$PosYLabel = GUICtrlCreateLabel("Pos Y: N/A", 20, 120, 250, 20)
$HPLabel = GUICtrlCreateLabel("HP: N/A", 20, 150, 250, 20)
$HP2Label = GUICtrlCreateLabel("HP2: N/A", 20, 180, 250, 20)
$MaxHPLabel = GUICtrlCreateLabel("MaxHP: N/A", 20, 210, 250, 20)
$HealerLabel = GUICtrlCreateLabel("Healer: OFF", 20, 240, 250, 20)
$HotkeyLabel = GUICtrlCreateLabel("Healer Hotkey: " & $HealerHotkey, 20, 270, 250, 20)
$ChangeHotkeyButton = GUICtrlCreateButton("Change Hotkey", 280, 270, 150, 30)
$PotsNote = GUICtrlCreateLabel("Pots go in #2", 20, 300, 250, 20)

; Slider for dynamic healing percentage
$SliderLabel = GUICtrlCreateLabel("Heal if HP below: " & $SliderValue & "%", 20, 330, 250, 20)
$Slider = GUICtrlCreateSlider(20, 360, 200, 30)
GUICtrlSetLimit($Slider, 100, 50)
GUICtrlSetData($Slider, $SliderValue)

; Slider for refresh rate (50ms to 150ms)
$RefreshLabel = GUICtrlCreateLabel("Refresh Rate: " & $RefreshRate & "ms", 20, 400, 250, 20)
$RefreshSlider = GUICtrlCreateSlider(20, 430, 200, 30)
GUICtrlSetLimit($RefreshSlider, 150, 50) ; Set slider range from 50ms to 150ms
GUICtrlSetData($RefreshSlider, $RefreshRate)

$KillButton = GUICtrlCreateButton("Kill Rogue", 20, 480, 100, 30)
$ExitButton = GUICtrlCreateButton("Exit", 150, 480, 100, 30)
GUISetState(@SW_SHOW)

$ProcessID = ProcessExists("Project Rogue Client.exe")
If $ProcessID Then
    If $DebugMode Then ConsoleWrite("Process found. Process ID: " & $ProcessID & @CRLF)
    $MemOpen = _MemoryOpen($ProcessID)

    ; Get the base address of the main module (Project Rogue Client.exe)
    $BaseAddress = _EnumProcessModules($MemOpen)

    If $BaseAddress = 0 Then
        If $DebugMode Then ConsoleWrite("Error: Failed to get base address" & @CRLF)
        MsgBox(0, "Error", "Failed to get base address")
        Exit
    EndIf

    If $DebugMode Then ConsoleWrite("Base Address: " & Hex($BaseAddress) & @CRLF)

    $TypeAddress = $BaseAddress + 0xBEEA34
    $AttackModeAddress = $BaseAddress + 0xAC0D60
    $ChatStatusAddress = $BaseAddress + 0x9B5998 ; Chat memory address
    $PosXAddress = $BaseAddress + 0xBF1C6C
    $PosYAddress = $BaseAddress + 0xBF1C64
    $HPAddress = $BaseAddress + 0x9BE988
    $MaxHPAddress = $BaseAddress + 0x9BE98C

    While 1
        $msg = GUIGetMsg()

        ; Check for exit button, kill button, or hotkey change button actions
        Select
            Case $msg = $ExitButton
                ; Save the slider values and refresh rate to the config file before exiting
                IniWrite($configFile, "Settings", "HealPercentage", GUICtrlRead($Slider))
                IniWrite($configFile, "Settings", "HealerHotkey", $HealerHotkey)
                IniWrite($configFile, "Settings", "RefreshRate", GUICtrlRead($RefreshSlider))
                _MemoryClose($MemOpen)
                Exit
            Case $msg = $KillButton
                ProcessClose($ProcessID)
                Exit
            Case $msg = $ChangeHotkeyButton
                SetHealerHotkey() ; Call function to change the healer hotkey
        EndSelect

        ; Update the slider percentage label dynamically
        $SliderValue = GUICtrlRead($Slider)
        GUICtrlSetData($SliderLabel, "Heal if HP below: " & $SliderValue & "%")

        ; Update refresh rate slider and label
        $RefreshRate = GUICtrlRead($RefreshSlider)
        GUICtrlSetData($RefreshLabel, "Refresh Rate: " & $RefreshRate & "ms")

        ; Reading memory for Type, Attack Mode, and Chat Status
        $Type = _MemoryRead($TypeAddress, $MemOpen, "dword")
        $AttackMode = _MemoryRead($AttackModeAddress, $MemOpen, "dword")
        $ChatStatus = _MemoryRead($ChatStatusAddress, $MemOpen, "dword")

        ; Debugging for Attack Mode, Type, and Chat Status
        If $DebugMode Then
            ConsoleWrite("Attack Mode: " & $AttackMode & " | Type: " & $Type & " | Chat Status: " & $ChatStatus & @CRLF)
        EndIf

        Switch $Type
            Case 0
                GUICtrlSetData($TypeLabel, "Type: Player")
            Case 1
                GUICtrlSetData($TypeLabel, "Type: Monster")
            Case 2
                GUICtrlSetData($TypeLabel, "Type: NPC")
            Case 65535
                GUICtrlSetData($TypeLabel, "Type: No Target")
            Case Else
                GUICtrlSetData($TypeLabel, "Type: Unknown (" & $Type & ")")
        EndSwitch

        ; Attack Mode status update
        GUICtrlSetData($AttackModeLabel, "Attack Mode: " & ($AttackMode ? "Attack" : "Safe"))

        ; Tab Targeting for No Target (65535), only if chat is not open
        If $AttackMode = 1 And $Type = 65535 And $ChatStatus = 0 Then
            If $DebugMode Then ConsoleWrite("No target, sending TAB to acquire a target." & @CRLF)
            If WinActive("Project Rogue") Then
                ControlSend("Project Rogue", "", "", "{TAB}")
                Sleep(100)
            Else
                If $DebugMode Then ConsoleWrite("Project Rogue is not the active window." & @CRLF)
            EndIf
        ElseIf $ChatStatus = 1 Then
            If $DebugMode Then ConsoleWrite("Chat is open, pausing tab targeting." & @CRLF)
        ElseIf $AttackMode = 1 And ($Type = 0 Or $Type = 1) Then
            If $DebugMode Then ConsoleWrite("Player or Monster is targeted, no TAB sent." & @CRLF)
        EndIf

        ; Read and display PosX, PosY, HP, and MaxHP
        $PosX = _MemoryRead($PosXAddress, $MemOpen, "dword")
        $PosY = _MemoryRead($PosYAddress, $MemOpen, "dword")
        $HP = _MemoryRead($HPAddress, $MemOpen, "dword")
        $MaxHP = _MemoryRead($MaxHPAddress, $MemOpen, "dword")

        If $DebugMode Then ConsoleWrite("Pos X: " & $PosX & ", Pos Y: " & $PosY & ", HP: " & $HP & ", Max HP: " & $MaxHP & @CRLF)

        GUICtrlSetData($PosXLabel, "Pos X: " & $PosX)
        GUICtrlSetData($PosYLabel, "Pos Y: " & $PosY)
        GUICtrlSetData($HPLabel, "HP: " & $HP)
        GUICtrlSetData($MaxHPLabel, "MaxHP: " & $MaxHP)

        $HP2 = $HP / 65536
        GUICtrlSetData($HP2Label, "HP2: " & $HP2)

        ; Continue healing logic, using the slider value for the dynamic heal threshold, and pause if chat is open
        If $HealerStatus And $ChatStatus = 0 And $HP2 <= ($SliderValue / 100 * $MaxHP) Then
            ControlSend("", "", "", "2")
            Sleep($pottimer)
        ElseIf $ChatStatus = 1 Then
            If $DebugMode Then ConsoleWrite("Chat is open, pausing healing." & @CRLF)
        EndIf

        Sleep($RefreshRate) ; Use dynamic refresh rate based on the slider
    WEnd
Else
    MsgBox(0, "Error", "Project Rogue Client.exe not found.")
EndIf

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

Func ToggleHealer()
    $HealerStatus = Not $HealerStatus
    GUICtrlSetData($HealerLabel, "Healer: " & ($HealerStatus ? "ON" : "OFF"))
EndFunc

Func SetHealerHotkey()
    ; Prompt the user to press a key for the new hotkey
    $newHotkey = InputBox("Set Healer Hotkey", "Press the new key for the healer hotkey:")

    If StringLen($newHotkey) > 0 Then
        ; Unset the previous hotkey
        HotKeySet($HealerHotkey)

        ; Set the new hotkey
        $HealerHotkey = $newHotkey
        HotKeySet($HealerHotkey, "ToggleHealer")

        ; Update the GUI and save to config
        GUICtrlSetData($HotkeyLabel, "Healer Hotkey: " & $HealerHotkey)
        IniWrite($configFile, "Settings", "HealerHotkey", $HealerHotkey)
    EndIf
EndFunc
