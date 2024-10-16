#include "NomadMemory.au3"
#include <GUIConstantsEx.au3>
#include <Misc.au3>
#include <File.au3>
#include <Array.au3>

; ---------------------------- Global Variables ----------------------------
Global $DebugMode = 0 ; Enable debugging output
Global $configFile = @ScriptDir & "\config.ini" ; Path to the config file
Global $HealerStatus = False
Global $HealerHotkey = "`" ; Default hotkey for healer
Global $RefreshRate = 50 ; Default refresh rate (50ms)
Global $pottimer = 2000
Global $gameWindowHandle ; To hold the window handle for "Project Rogue"

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

    ; Debug output for calculated memory addresses
    If $DebugMode Then
        ConsoleWrite("Calculated Type Address: " & Hex($TypeAddress) & @CRLF)
        ConsoleWrite("Calculated Attack Mode Address: " & Hex($AttackModeAddress) & @CRLF)
        ConsoleWrite("Calculated PosX Address: " & Hex($PosXAddress) & @CRLF)
        ConsoleWrite("Calculated PosY Address: " & Hex($PosYAddress) & @CRLF)
        ConsoleWrite("Calculated HP Address: " & Hex($HPAddress) & @CRLF)
        ConsoleWrite("Calculated MaxHP Address: " & Hex($MaxHPAddress) & @CRLF)
        ConsoleWrite("Calculated Chat Status Address: " & Hex($ChatStatusAddress) & @CRLF)
    EndIf

    ; Get the window handle for Project Rogue
    $gameWindowHandle = WinGetHandle("Project Rogue")
    If $gameWindowHandle = "" Then
        MsgBox(0, "Error", "Game window not found.")
        Exit
    Else
        If $DebugMode Then ConsoleWrite("Game window handle found: " & $gameWindowHandle & @CRLF)
    EndIf

Else
    MsgBox(0, "Error", "Project Rogue Client.exe not found.")
    Exit
EndIf

; ---------------------------- GUI Creation ----------------------------
$Gui = GUICreate("RogueReader", 450, 600, 15, 15) ; Increased height for the new chat status and buttons
Local $TypeLabel = GUICtrlCreateLabel("Type: N/A", 20, 30, 250, 20)
Local $AttackModeLabel = GUICtrlCreateLabel("Attack Mode: N/A", 20, 60, 250, 20)
Local $PosXLabel = GUICtrlCreateLabel("Pos X: N/A", 20, 90, 250, 20)
Local $PosYLabel = GUICtrlCreateLabel("Pos Y: N/A", 20, 120, 250, 20)
Local $HPLabel = GUICtrlCreateLabel("HP: N/A", 20, 150, 250, 20)
Local $MaxHPLabel = GUICtrlCreateLabel("MaxHP: N/A", 20, 180, 250, 20)
Local $ChatStatusLabel = GUICtrlCreateLabel("Chat: N/A", 20, 210, 250, 20) ; New chat status label
Local $HealerLabel = GUICtrlCreateLabel("Healer: OFF", 20, 240, 250, 20)
Local $HotkeyLabel = GUICtrlCreateLabel("Healer Hotkey: " & $HealerHotkey, 20, 270, 250, 20)

; Button to change the healer hotkey
Local $ChangeHotkeyButton = GUICtrlCreateButton("Change Healer Hotkey", 280, 270, 150, 30)

; Slider for dynamic healing percentage
Local $SliderLabel = GUICtrlCreateLabel("Heal if HP below: 95%", 20, 310, 250, 20)
Local $Slider = GUICtrlCreateSlider(20, 340, 200, 30)
GUICtrlSetLimit($Slider, 100, 50) ; Limit the slider between 50% and 100%
GUICtrlSetData($Slider, 95)

; Slider for refresh rate (50ms to 150ms)
Local $RefreshLabel = GUICtrlCreateLabel("Refresh Rate: 50ms", 20, 390, 250, 20)
Local $RefreshSlider = GUICtrlCreateSlider(20, 420, 200, 30)
GUICtrlSetLimit($RefreshSlider, 150, 50) ; 50ms to 150ms
GUICtrlSetData($RefreshSlider, $RefreshRate)

; Buttons to close Rogue and Exit
Local $KillButton = GUICtrlCreateButton("Kill Rogue", 20, 480, 100, 30)
Local $ExitButton = GUICtrlCreateButton("Exit", 150, 480, 100, 30)

GUISetState(@SW_SHOW)

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
    Local $Type = _MemoryRead($TypeAddress, $MemOpen, "dword")
    Local $AttackMode = _MemoryRead($AttackModeAddress, $MemOpen, "dword")
    Local $PosX = _MemoryRead($PosXAddress, $MemOpen, "dword")
    Local $PosY = _MemoryRead($PosYAddress, $MemOpen, "dword")
    Local $HP = _MemoryRead($HPAddress, $MemOpen, "dword")
    Local $MaxHP = _MemoryRead($MaxHPAddress, $MemOpen, "dword")
    Local $ChatStatus = _MemoryRead($ChatStatusAddress, $MemOpen, "dword") ; Reading chat status

    ; Debug output for memory values
    If $DebugMode Then
        ConsoleWrite("Type: " & $Type & @CRLF)
        ConsoleWrite("Attack Mode: " & $AttackMode & @CRLF)
        ConsoleWrite("PosX: " & $PosX & @CRLF)
        ConsoleWrite("PosY: " & $PosY & @CRLF)
        ConsoleWrite("HP: " & $HP & @CRLF)
        ConsoleWrite("MaxHP: " & $MaxHP & @CRLF)
        ConsoleWrite("Chat Status: " & $ChatStatus & @CRLF)
    EndIf

    ; Update the GUI labels based on conditions for Type and Attack Mode
    If $Type = 65536 Then
        GUICtrlSetData($TypeLabel, "Type: None")
    ElseIf $Type = 1 Then
        GUICtrlSetData($TypeLabel, "Type: Monster")
    ElseIf $Type = 2 Then
        GUICtrlSetData($TypeLabel, "Type: Player")
    Else
        GUICtrlSetData($TypeLabel, "Type: N/A")
    EndIf

    If $AttackMode = 1 Then
        GUICtrlSetData($AttackModeLabel, "Attack Mode: Attack")
    ElseIf $AttackMode = 0 Then
        GUICtrlSetData($AttackModeLabel, "Attack Mode: Safe")
    Else
        GUICtrlSetData($AttackModeLabel, "Attack Mode: N/A")
    EndIf

    ; Update Chat Status in GUI
    If $ChatStatus = 0 Then
        GUICtrlSetData($ChatStatusLabel, "Chat: Closed")
    ElseIf $ChatStatus = 1 Then
        GUICtrlSetData($ChatStatusLabel, "Chat: Open")
    EndIf

    ; Update other GUI labels
    GUICtrlSetData($PosXLabel, "Pos X: " & $PosX)
    GUICtrlSetData($PosYLabel, "Pos Y: " & $PosY)
    GUICtrlSetData($HPLabel, "HP: " & $HP)
    GUICtrlSetData($MaxHPLabel, "MaxHP: " & $MaxHP)

    ; Update sliders
    Local $SliderValue = GUICtrlRead($Slider)
    GUICtrlSetData($SliderLabel, "Heal if HP below: " & $SliderValue & "%")

    $RefreshRate = GUICtrlRead($RefreshSlider)
    GUICtrlSetData($RefreshLabel, "Refresh Rate: " & $RefreshRate & "ms")

    ; Tab Targeting Debugging and Sending Tab in Background
    If $AttackMode = 1 And $Type = 65535 And $ChatStatus = 0 Then
        ; Use ControlSend to send the Tab key to the background window
        If $DebugMode Then ConsoleWrite("Sending Tab to background window..." & @CRLF)
        ControlSend($gameWindowHandle, "", "", "{TAB}")
        Sleep(100)
    EndIf

    ; Healing Logic with Debugging
    Local $HP2 = Round($HP / 65536, 2)
    If $HealerStatus And $ChatStatus = 0 And $HP2 <= ($SliderValue / 100 * $MaxHP) Then
        If $DebugMode Then ConsoleWrite("Healing... HP is below threshold." & @CRLF)
        ControlSend("", "", "", "2")
        Sleep($pottimer)
    EndIf

    Sleep($RefreshRate)
WEnd

; ---------------------------- Functions ----------------------------

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

Func SaveSettings()
    ; Save slider values to the config file
    IniWrite($configFile, "Settings", "HealPercentage", GUICtrlRead($Slider))
    IniWrite($configFile, "Settings", "RefreshRate", GUICtrlRead($RefreshSlider))
EndFunc

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

; Function to toggle healer on/off
Func ToggleHealer()
    $HealerStatus = Not $HealerStatus
    GUICtrlSetData($HealerLabel, "Healer: " & ($HealerStatus ? "ON" : "OFF"))
    If $DebugMode Then ConsoleWrite("Healer toggled: " & ($HealerStatus ? "ON" : "OFF") & @CRLF)
EndFunc
