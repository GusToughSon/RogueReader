#include "NomadMemory.au3"
#include <GUIConstantsEx.au3>
#include <Misc.au3>
#include <File.au3>
#include <Array.au3>

; ---------------------------- Global Variables ----------------------------
Global $DebugMode = 1 ; Enable debugging output (set to 1 to turn on, 0 to turn off)
Global $configFile = @ScriptDir & "\config.ini" ; Path to the config file
Global $HealerStatus = False
Global $HealerHotkey = "`" ; Default hotkey for healer
Global $RefreshRate = 50 ; Default refresh rate (50ms)
Global $pottimer = 2000
Global $gameWindowHandle ; To hold the window handle for "Project Rogue"
Global $ExitButton, $KillButton, $ChangeHotkeyButton
Global $TypeLabel, $AttackModeLabel, $PosXLabel, $PosYLabel, $HPLabel, $MaxHPLabel, $ChatStatusLabel, $SliderLabel, $Slider, $RefreshSlider, $RefreshLabel
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
    $ChatStatusAddress = $BaseAddress + 0x9B5998 ; Address for chat status

    If $DebugMode Then
        ConsoleWrite("Memory addresses calculated: " & @CRLF)
        ConsoleWrite("Type Address: " & Hex($TypeAddress) & @CRLF)
        ConsoleWrite("Attack Mode Address: " & Hex($AttackModeAddress) & @CRLF)
        ConsoleWrite("Pos X Address: " & Hex($PosXAddress) & @CRLF)
        ConsoleWrite("Pos Y Address: " & Hex($PosYAddress) & @CRLF)
        ConsoleWrite("HP Address: " & Hex($HPAddress) & @CRLF)
        ConsoleWrite("Max HP Address: " & Hex($MaxHPAddress) & @CRLF)
        ConsoleWrite("Chat Status Address: " & Hex($ChatStatusAddress) & @CRLF)
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
$Gui = GUICreate("RogueReader", 450, 600, 15, 15) ; Increased height for the new chat status and buttons
$TypeLabel = GUICtrlCreateLabel("Type: N/A", 20, 30, 250, 20)
$AttackModeLabel = GUICtrlCreateLabel("Attack Mode: N/A", 20, 60, 250, 20)
$PosXLabel = GUICtrlCreateLabel("Pos X: N/A", 20, 90, 250, 20)
$PosYLabel = GUICtrlCreateLabel("Pos Y: N/A", 20, 120, 250, 20)
$HPLabel = GUICtrlCreateLabel("HP: N/A", 20, 150, 250, 20)
$MaxHPLabel = GUICtrlCreateLabel("MaxHP: N/A", 20, 180, 250, 20)
$ChatStatusLabel = GUICtrlCreateLabel("Chat: N/A", 20, 210, 250, 20) ; New chat status label
$HealerLabel = GUICtrlCreateLabel("Healer: OFF", 20, 240, 250, 20)
$HotkeyLabel = GUICtrlCreateLabel("Healer Hotkey: " & $HealerHotkey, 20, 270, 250, 20)

; Button to change the healer hotkey
$ChangeHotkeyButton = GUICtrlCreateButton("Change Healer Hotkey", 280, 270, 150, 30)

; Slider for dynamic healing percentage
$SliderLabel = GUICtrlCreateLabel("Heal if HP below: 95%", 20, 310, 250, 20)
$Slider = GUICtrlCreateSlider(20, 340, 200, 30)
GUICtrlSetLimit($Slider, 100, 50) ; Limit the slider between 50% and 100%
GUICtrlSetData($Slider, 95)

; Slider for refresh rate (50ms to 150ms)
$RefreshLabel = GUICtrlCreateLabel("Refresh Rate: 50ms", 20, 390, 250, 20)
$RefreshSlider = GUICtrlCreateSlider(20, 420, 200, 30)
GUICtrlSetLimit($RefreshSlider, 150, 50) ; 50ms to 150ms
GUICtrlSetData($RefreshSlider, $RefreshRate)

; Buttons to close Rogue and Exit
$KillButton = GUICtrlCreateButton("Kill Rogue", 20, 480, 100, 30)
$ExitButton = GUICtrlCreateButton("Exit", 150, 480, 100, 30)

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

    EndSelect

    ; Read memory values with debug outputs
    Local $Type = ReadType()
    Local $AttackMode = ReadAttackMode()
    Local $PosX = ReadPosX()
    Local $PosY = ReadPosY()
    Local $HP = ReadHP()
    Local $MaxHP = ReadMaxHP()
    Local $ChatStatus = ReadChatStatus()

    ; ---------------- GUI Updates ----------------
    ; Ensure GUI is updated after reading memory values

    ; Update the GUI with correct values
    GUICtrlSetData($TypeLabel, "Type: " & $Type)
    GUICtrlSetData($AttackModeLabel, "Attack Mode: " & $AttackMode)
    GUICtrlSetData($PosXLabel, "Pos X: " & $PosX)
    GUICtrlSetData($PosYLabel, "Pos Y: " & $PosY)
    GUICtrlSetData($HPLabel, "HP: " & $HP)
    GUICtrlSetData($MaxHPLabel, "MaxHP: " & $MaxHP)

    ; Update Chat Status Label
    If $ChatStatus = 0 Then
        GUICtrlSetData($ChatStatusLabel, "Chat: Closed")
    ElseIf $ChatStatus = 1 Then
        GUICtrlSetData($ChatStatusLabel, "Chat: Open")
    EndIf

    ; Debug to ensure values are correct
    If $DebugMode Then
        ConsoleWrite("Type: " & $Type & @CRLF)
        ConsoleWrite("Attack Mode: " & $AttackMode & @CRLF)
        ConsoleWrite("HP: " & $HP & " MaxHP: " & $MaxHP & @CRLF)
        ConsoleWrite("Pos X: " & $PosX & " Pos Y: " & $PosY & @CRLF)
        ConsoleWrite("Chat Status: " & $ChatStatus & @CRLF)
    EndIf

    ; ---------------- Healing Logic ----------------
    Local $SliderValue = GUICtrlRead($Slider) ; Get the heal percentage from the slider

    ; Calculate HP percentage
    If $MaxHP > 0 Then
        Local $HPPercentage = ($HP / $MaxHP) * 100

        ; If the healer is on, chat is closed, and HP is below the threshold, heal
        If $HealerStatus And $ChatStatus = 0 And $HPPercentage <= $SliderValue Then
            If $DebugMode Then ConsoleWrite("Healing... HP is below threshold." & @CRLF)

            ; Send the key press for healing (default: key "2")
            ControlSend($gameWindowHandle, "", "", "2")

            ; Sleep to prevent spamming the heal action too fast
            Sleep($pottimer)
        EndIf
    EndIf

    ; Update the GUI labels
    GUICtrlSetData($SliderLabel, "Heal if HP below: " & $SliderValue & "%")

    ; ------------------- Tab Targeting Logic -------------------
    If ($AttackMode = 1 And ($Type = 65535 Or $Type = 0) And $ChatStatus = 0) Then
        If $DebugMode Then ConsoleWrite("Tab Targeting: Sending Tab key to game window." & @CRLF)

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
    If $DebugMode Then ConsoleWrite("Healer toggled: " & ($HealerStatus ? "ON" : "OFF") & @CRLF)
EndFunc

; ---------------------------- SetHealerHotkey Function ----------------------------
Func SetHealerHotkey()
    Local $newHotkey = InputBox("Set Healer Hotkey", "Press the new key for the healer hotkey:")

    If StringLen($newHotkey) > 0 Then
        HotKeySet($HealerHotkey)
        $HealerHotkey = $newHotkey
        HotKeySet($HealerHotkey, "ToggleHealer")
        GUICtrlSetData($HotkeyLabel, "Healer Hotkey: " & $HealerHotkey)
        IniWrite($configFile, "Settings", "HealerHotkey", $HealerHotkey)
        If $DebugMode Then ConsoleWrite("Healer hotkey set to: " & $HealerHotkey & @CRLF)
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
