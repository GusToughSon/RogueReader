#include "NomadMemory.au3"
#include <GUIConstantsEx.au3>
#include <Misc.au3>
#include <File.au3>
#include <Array.au3>
#include <WindowsConstants.au3> ; For window styles like $WS_VSCROLL
#include <EditConstants.au3>    ; For $ES_READONLY constant

; ---------------------------- Global Variables ----------------------------
Global $DebugMode = 0 ; Enable debugging output (set to 0 to turn off by default)
Global $configFile = @ScriptDir & "\config.ini" ; Path to the config file
Global $HealerStatus = False
Global $HealerHotkey = "`" ; Default hotkey for healer
Global $RefreshRate = 50 ; Default refresh rate (50ms)
Global $pottimer = 2000
Global $gameWindowHandle ; To hold the window handle for "Project Rogue"
Global $ExitButton, $KillButton, $ChangeHotkeyButton, $DebugButton
Global $TypeLabel, $AttackModeLabel, $PosXLabel, $PosYLabel, $HPLabel, $MaxHPLabel, $ChatStatusLabel, $AilmentLabel
Global $SliderLabel, $Slider, $RefreshSlider, $RefreshLabel, $DebugLabel
Global $MemOpen, $ProcessID

; ---------------------------- Memory Debugging Setup ----------------------------
$ProcessID = ProcessExists("Project Rogue Client.exe")
If $ProcessID Then
    If $DebugMode Then ConsoleWrite("Process found. Process ID: " & $ProcessID & @CRLF)
    $MemOpen = _MemoryOpen($ProcessID)

    ; Fetch base address with debugging
    $BaseAddress = _EnumProcessModules($MemOpen)
    If $BaseAddress = 0 Then
        If $DebugMode Then ConsoleWrite("Error: Failed to get base address" & @CRLF)
        MsgBox(0, "Error", "Failed to get base address")
        Exit
    EndIf
    If $DebugMode Then ConsoleWrite("Base Address: " & Hex($BaseAddress) & @CRLF)

    ; Define memory addresses relative to the base address
    $TypeAddress = $BaseAddress + 0xBEEA34
    $AttackModeAddress = $BaseAddress + 0xAC0D60
    $PosXAddress = $BaseAddress + 0xBF1C6C
    $PosYAddress = $BaseAddress + 0xBF1C64
    $HPAddress = $BaseAddress + 0x9BE988
    $MaxHPAddress = $BaseAddress + 0x9BE98C
    $ChatStatusAddress = $BaseAddress + 0x9B5998
    $AilmentAddress = $BaseAddress + 0x9BEB5C ; Address for ailment status

    If $DebugMode Then
        ConsoleWrite("Memory addresses calculated: " & @CRLF)
        ConsoleWrite("Type Address: " & Hex($TypeAddress) & @CRLF)
        ConsoleWrite("Attack Mode Address: " & Hex($AttackModeAddress) & @CRLF)
        ConsoleWrite("Pos X Address: " & Hex($PosXAddress) & @CRLF)
        ConsoleWrite("Pos Y Address: " & Hex($PosYAddress) & @CRLF)
        ConsoleWrite("HP Address: " & Hex($HPAddress) & @CRLF)
        ConsoleWrite("Max HP Address: " & Hex($MaxHPAddress) & @CRLF)
        ConsoleWrite("Chat Status Address: " & Hex($ChatStatusAddress) & @CRLF)
        ConsoleWrite("Ailment Address: " & Hex($AilmentAddress) & @CRLF)
    EndIf

    ; Get the window handle for Project Rogue
    $gameWindowHandle = WinGetHandle("Project Rogue")
    If $gameWindowHandle = "" Or Not WinExists($gameWindowHandle) Then
        MsgBox(0, "Error", "Game window not found.")
        Exit
    Else
        If $DebugMode Then ConsoleWrite("Game window handle found: " & $gameWindowHandle & @CRLF)
    EndIf

Else
    MsgBox(0, "Error", "Project Rogue Client.exe not found.")
    Exit
EndIf

; ---------------------------- EnumProcessModules Function ----------------------------
Func _EnumProcessModules($hProcess)
    Local $hMod = DllStructCreate("ptr")
    Local $moduleSize = DllStructGetSize($hMod)

    Local $aModules = DllCall("psapi.dll", "int", "EnumProcessModulesEx", "ptr", $hProcess, "ptr", DllStructGetPtr($hMod), "dword", $moduleSize, "dword*", 0, "dword", 0x03)

    If IsArray($aModules) And $aModules[0] <> 0 Then
        Return DllStructGetData($hMod, 1)
    Else
        Return 0
    EndIf
EndFunc

; ---------------------------- GUI Creation ----------------------------
$Gui = GUICreate("RogueReader", 750, 650, 15, 15)
$TypeLabel = GUICtrlCreateLabel("Type: N/A", 20, 30, 250, 20)
$AttackModeLabel = GUICtrlCreateLabel("Attack Mode: N/A", 20, 60, 250, 20)
$PosXLabel = GUICtrlCreateLabel("Pos X: N/A", 20, 90, 250, 20)
$PosYLabel = GUICtrlCreateLabel("Pos Y: N/A", 20, 120, 250, 20)
$HPLabel = GUICtrlCreateLabel("HP: N/A", 20, 150, 250, 20)
$MaxHPLabel = GUICtrlCreateLabel("MaxHP: N/A", 20, 180, 250, 20)
$ChatStatusLabel = GUICtrlCreateLabel("Chat: N/A", 20, 210, 250, 20)
$AilmentLabel = GUICtrlCreateLabel("Ailment: N/A", 20, 240, 250, 20)
$HealerLabel = GUICtrlCreateLabel("Healer: OFF", 20, 270, 250, 20)
$HotkeyLabel = GUICtrlCreateLabel("Healer Hotkey: " & $HealerHotkey, 20, 300, 250, 20)

; Button to change the healer hotkey
$ChangeHotkeyButton = GUICtrlCreateButton("Change Healer Hotkey", 280, 300, 150, 30)

; Slider for dynamic healing percentage
$SliderLabel = GUICtrlCreateLabel("Heal if HP below: 95%", 20, 340, 250, 20)
$Slider = GUICtrlCreateSlider(20, 370, 200, 30)
GUICtrlSetLimit($Slider, 100, 50) ; Limit the slider between 50% and 100%
GUICtrlSetData($Slider, 95)

; Slider for refresh rate (50ms to 150ms)
$RefreshLabel = GUICtrlCreateLabel("Refresh Rate: 50ms", 20, 420, 250, 20)
$RefreshSlider = GUICtrlCreateSlider(20, 450, 200, 30)
GUICtrlSetLimit($RefreshSlider, 150, 50) ; 50ms to 150ms
GUICtrlSetData($RefreshSlider, $RefreshRate)

; Buttons to close Rogue and Exit
$KillButton = GUICtrlCreateButton("Kill Rogue", 20, 500, 100, 30)
$ExitButton = GUICtrlCreateButton("Exit", 150, 500, 100, 30)

; Button and Label to toggle debug mode
$DebugButton = GUICtrlCreateButton("Toggle Debug", 280, 500, 150, 30)
$DebugLabel = GUICtrlCreateLabel("Debug: OFF", 20, 550, 250, 20)

GUISetState(@SW_SHOW)

; ---------------------------- Load Settings Function ----------------------------
Func LoadSettings()
    If $DebugMode Then ConsoleWrite("Loading settings from config file..." & @CRLF)

    ; Load heal percentage
    $HealPercentage = IniRead($configFile, "Settings", "HealPercentage", 95)
    GUICtrlSetData($Slider, $HealPercentage)
    If $DebugMode Then ConsoleWrite("Loaded Heal Percentage: " & $HealPercentage & @CRLF)

    ; Load refresh rate
    $RefreshRate = IniRead($configFile, "Settings", "RefreshRate", 50)
    GUICtrlSetData($RefreshSlider, $RefreshRate)
    If $DebugMode Then ConsoleWrite("Loaded Refresh Rate: " & $RefreshRate & " ms" & @CRLF)

    ; Load healer hotkey
    $HealerHotkey = IniRead($configFile, "Settings", "HealerHotkey", "`")
    GUICtrlSetData($HotkeyLabel, "Healer Hotkey: " & $HealerHotkey)
    HotKeySet($HealerHotkey, "ToggleHealer")
    If $DebugMode Then ConsoleWrite("Loaded Healer Hotkey: " & $HealerHotkey & @CRLF)
EndFunc

; ---------------------------- Save Settings Function ----------------------------
Func SaveSettings()
    If $DebugMode Then ConsoleWrite("Saving settings to config file..." & @CRLF)

    ; Save the slider values to the config file
    IniWrite($configFile, "Settings", "HealPercentage", GUICtrlRead($Slider))
    IniWrite($configFile, "Settings", "RefreshRate", GUICtrlRead($RefreshSlider))
    IniWrite($configFile, "Settings", "HealerHotkey", $HealerHotkey)

    If $DebugMode Then ConsoleWrite("Settings saved successfully!" & @CRLF)
EndFunc

; Load settings AFTER GUI creation
LoadSettings()

; ---------------------------- Main Loop ----------------------------
While 1
    Local $msg = GUIGetMsg()

    Select
        Case $msg = $ExitButton
            SaveSettings()
            _MemoryClose($MemOpen)
            Exit

        Case $msg = $KillButton
            ProcessClose($ProcessID)
            Exit

        Case $msg = $ChangeHotkeyButton
            SetHealerHotkey() ; Function to set healer hotkey

        Case $msg = $DebugButton
            ToggleDebug() ; Function to toggle debug messages

    EndSelect

    ; Read memory values with debug outputs
    Local $Type = ReadType()
    Local $AttackMode = ReadAttackMode()
    Local $PosX = ReadPosX()
    Local $PosY = ReadPosY()
    Local $HP = Round(ReadHP() / 65535, 2) ; Divide HP by 65535
    Local $MaxHP = ReadMaxHP()
    Local $ChatStatus = ReadChatStatus()
    Local $Ailment = ReadAilment()

    ; ---------------- GUI Updates ----------------
    ; Update Attack Mode based on its value
    If $AttackMode = 0 Then
        GUICtrlSetData($AttackModeLabel, "Attack Mode: Safe")
    ElseIf $AttackMode = 1 Then
        GUICtrlSetData($AttackModeLabel, "Attack Mode: Attack")
    Else
        GUICtrlSetData($AttackModeLabel, "Attack Mode: Unknown")
    EndIf

    ; Update Type based on its value
    If $Type = 0 Or $Type = 65535 Then
        GUICtrlSetData($TypeLabel, "Type: None")
    ElseIf $Type = 1 Then
        GUICtrlSetData($TypeLabel, "Type: Monster")
    ElseIf $Type = 2 Then
        GUICtrlSetData($TypeLabel, "Type: Player")
    Else
        GUICtrlSetData($TypeLabel, "Type: Unknown (" & $Type & ")")
    EndIf

    ; Update Ailment based on its value
    If $Ailment = 0 Then
        GUICtrlSetData($AilmentLabel, "Ailment: None")
    ElseIf $Ailment = 1 Then
        GUICtrlSetData($AilmentLabel, "Ailment: Poisoned")
    ElseIf $Ailment = 2 Then
        GUICtrlSetData($AilmentLabel, "Ailment: Diseased")
    Else
        GUICtrlSetData($AilmentLabel, "Ailment: Unknown (" & $Ailment & ")")
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

    ; ---------------- Healing Logic ----------------
    Local $SliderValue = GUICtrlRead($Slider) ; Get the heal percentage from the slider

    If $MaxHP > 0 Then
        Local $HPPercentage = ($HP / $MaxHP) * 100

        ; Check if the healer is on, chat is closed, and HP is below the threshold
        If $HealerStatus And $ChatStatus = 0 And $HPPercentage <= $SliderValue Then
            ConsoleWrite("Healing... HP is below threshold." & @CRLF)

            ; Verify game window handle before sending key
            If $gameWindowHandle <> "" And WinExists($gameWindowHandle) Then
                ; Send key press for healing (default: "2")
                ConsoleWrite("Sending key '2' to the game window." & @CRLF)

                ; Send the key press
                ControlSend($gameWindowHandle, "", "", "2")

                ; Sleep to prevent spamming the heal action too fast
                Sleep($pottimer)
            Else
                ConsoleWrite("Error: Game window handle is invalid or not found." & @CRLF)
            EndIf
        EndIf
    EndIf

    ; Update the GUI labels
    GUICtrlSetData($SliderLabel, "Heal if HP below: " & $SliderValue & "%")

    ; ------------------- Tab Targeting Logic -------------------
    If ($AttackMode = 1 And ($Type = 65535 Or $Type = 0) And $ChatStatus = 0) Then
        ConsoleWrite("Tab Targeting: Sending Tab key to game window." & @CRLF)

        ; Send Tab key to the game window to cycle targets
        ControlSend($gameWindowHandle, "", "", "{TAB}")

        ; Sleep briefly to allow for target acquisition
        Sleep(300)
    EndIf

    Sleep($RefreshRate)
WEnd

; ---------------------------- ToggleHealer Function ----------------------------
Func ToggleHealer()
    $HealerStatus = Not $HealerStatus
    GUICtrlSetData($HealerLabel, "Healer: " & ($HealerStatus ? "ON" : "OFF"))
    ConsoleWrite("Healer toggled: " & ($HealerStatus ? "ON" : "OFF") & @CRLF)
EndFunc

; ---------------------------- SetHealerHotkey Function ----------------------------
Func SetHealerHotkey()
    Local $newHotkey = InputBox("Set Healer Hotkey", "Press the new key for the healer hotkey:")

    If StringLen($newHotkey) > 0 Then
        HotKeySet($HealerHotkey) ; Unset the old hotkey
        $HealerHotkey = $newHotkey
        HotKeySet($HealerHotkey, "ToggleHealer") ; Set the new hotkey
        GUICtrlSetData($HotkeyLabel, "Healer Hotkey: " & $HealerHotkey)
        IniWrite($configFile, "Settings", "HealerHotkey", $HealerHotkey)
        ConsoleWrite("Healer hotkey set to: " & $HealerHotkey & @CRLF)
    EndIf
EndFunc

; ---------------------------- Toggle Debug Mode Function ----------------------------
Func ToggleDebug()
    $DebugMode = Not $DebugMode
    If $DebugMode Then
        GUICtrlSetData($DebugLabel, "Debug: ON")
        ConsoleWrite("Debug mode turned ON." & @CRLF)
    Else
        GUICtrlSetData($DebugLabel, "Debug: OFF")
        ConsoleWrite("Debug mode turned OFF." & @CRLF)
    EndIf
EndFunc

; ---------------------------- Modularized Memory Reading Functions ----------------------------
Func ReadType()
    Local $Type = _MemoryRead($TypeAddress, $MemOpen, "dword")
    If $DebugMode Then ConsoleWrite("Type Read: " & $Type & @CRLF)
    Return $Type
EndFunc

Func ReadAttackMode()
    Local $AttackMode = _MemoryRead($AttackModeAddress, $MemOpen, "dword")
    If $DebugMode Then ConsoleWrite("Attack Mode Read: " & $AttackMode & @CRLF)
    Return $AttackMode
EndFunc

Func ReadPosX()
    Local $PosX = _MemoryRead($PosXAddress, $MemOpen, "dword")
    If $DebugMode Then ConsoleWrite("Position X Read: " & $PosX & @CRLF)
    Return $PosX
EndFunc

Func ReadPosY()
    Local $PosY = _MemoryRead($PosYAddress, $MemOpen, "dword")
    If $DebugMode Then ConsoleWrite("Position Y Read: " & $PosY & @CRLF)
    Return $PosY
EndFunc

Func ReadHP()
    Local $HP = _MemoryRead($HPAddress, $MemOpen, "dword")
    If $DebugMode Then ConsoleWrite("HP Read: " & $HP & @CRLF)
    Return $HP
EndFunc

Func ReadMaxHP()
    Local $MaxHP = _MemoryRead($MaxHPAddress, $MemOpen, "dword")
    If $DebugMode Then ConsoleWrite("Max HP Read: " & $MaxHP & @CRLF)
    Return $MaxHP
EndFunc

Func ReadChatStatus()
    Local $ChatStatus = _MemoryRead($ChatStatusAddress, $MemOpen, "dword")
    If $DebugMode Then ConsoleWrite("Chat Status Read: " & $ChatStatus & @CRLF)
    Return $ChatStatus
EndFunc

; ---------------------------- Ailment Reading Function ----------------------------
Func ReadAilment()
    Local $Ailment = _MemoryRead($AilmentAddress, $MemOpen, "dword")
    If $DebugMode Then ConsoleWrite("Ailment Read: " & $Ailment & @CRLF)
    Return $Ailment
EndFunc
