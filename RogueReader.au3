#include "NomadMemory.au3"
#include <GUIConstantsEx.au3>
#include <Misc.au3>
#include <File.au3>
#include <Array.au3>
#include "Gui.au3" ; Include the GUI file

; ---------------------------- Global Variables ----------------------------
Global $DebugMode = 0 ; Enable debugging output (set to 0 to turn off by default)
Global $configFile = @ScriptDir & "\config.ini" ; Path to the config file
Global $HealerStatus = False
Global $HealerHotkey = "`" ; Default hotkey for healer
Global $RefreshRate = 50 ; Default refresh rate (50ms)
Global $pottimer = 2000
Global $gameWindowHandle ; To hold the window handle for "Project Rogue"
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

    ; Define memory addresses relative to the base address (Updated addresses)
    $TypeAddress = $BaseAddress + 0xBEFA34 ; Holds the player's or character's type/class
    $AttackModeAddress = $BaseAddress + 0xAC1D60 ; Represents player's current attack mode
    $PosXAddress = $BaseAddress + 0xBF2C6C ; Holds the player's X-coordinate
    $PosYAddress = $BaseAddress + 0xBF2C64 ; Holds the player's Y-coordinate
    $HPAddress = $BaseAddress + 0x9BF988 ; Represents player's current health points
    $MaxHPAddress = $BaseAddress + 0x9BF98C ; Represents player's maximum health points
    $ChatStatusAddress = $BaseAddress + 0x9B6998 ; Holds the current chat status
    $AilmentAddress = $BaseAddress + 0x9BFB5C ; Represents the player's ailment or status effects

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

; ---------------------------- Set Healer Hotkey Function ----------------------------
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

; ---------------------------- Toggle Healer Function ----------------------------
Func ToggleHealer()
    $HealerStatus = Not $HealerStatus
    GUICtrlSetData($HealerLabel, "Healer: " & ($HealerStatus ? "ON" : "OFF"))
    ConsoleWrite("Healer toggled: " & ($HealerStatus ? "ON" : "OFF") & @CRLF)
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

; ---------------------------- Memory Reading Functions ----------------------------
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

Func ReadAilment()
    Local $Ailment = _MemoryRead($AilmentAddress, $MemOpen, "dword")
    If $DebugMode Then ConsoleWrite("Ailment Read: " & $Ailment & @CRLF)
    Return $Ailment
EndFunc

; ---------------------------- Main Program ----------------------------

; Create the GUI by calling the function from Gui.au3
CreateGUI()

; Load settings AFTER GUI creation
LoadSettings()

; Main loop
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
            SetHealerHotkey()

        Case $msg = $DebugButton
            ToggleDebug()

    EndSelect

    ; Read memory values
    Local $Type = ReadType()
    Local $AttackMode = ReadAttackMode()
    Local $PosX = ReadPosX()
    Local $PosY = ReadPosY()
    Local $HP = Round(ReadHP() / 65535, 2) ; Divide HP by 65535
    Local $MaxHP = ReadMaxHP()
    Local $ChatStatus = ReadChatStatus()
    Local $Ailment = ReadAilment()

    ; Update the GUI
    UpdateGUI($Type, $AttackMode, $PosX, $PosY, $HP, $MaxHP, $ChatStatus, $Ailment)

    ; ---------------- Ailment Handling ----------------
    ; If ailment is Poisoned (1) or Diseased (2), send "3" to cure the ailment
    If $Ailment = 1 Or $Ailment = 2 Then
        ConsoleWrite("Curing ailment... Ailment code: " & $Ailment & @CRLF)

        If $gameWindowHandle <> "" And WinExists($gameWindowHandle) Then
            ; Send key press for curing ailment (default: "3")
            ControlSend($gameWindowHandle, "", "", "3")
            ConsoleWrite("Sent key '3' to the game window to cure ailment." & @CRLF)

            ; Sleep to avoid spamming the cure action too quickly
            Sleep(1000)
        Else
            ConsoleWrite("Error: Game window handle is invalid or not found." & @CRLF)
        EndIf

        ; Skip healing if the player has an ailment
        ContinueLoop
    EndIf

    ; ---------------- Healing Logic (Only if No Ailment) ----------------
    Local $SliderValue = GUICtrlRead($Slider) ; Get the heal percentage from the slider

    If $MaxHP > 0 Then
        Local $HPPercentage = ($HP / $MaxHP) * 100

        ; Check if the healer is on, chat is closed, HP is below the threshold, and no ailment
        If $HealerStatus And $ChatStatus = 0 And $HPPercentage <= $SliderValue Then
            ConsoleWrite("Healing... HP is below threshold." & @CRLF)

            If $gameWindowHandle <> "" And WinExists($gameWindowHandle) Then
                ; Send key press for healing (default: "2")
                ControlSend($gameWindowHandle, "", "", "2")
                ConsoleWrite("Sent key '2' to the game window to heal." & @CRLF)

                ; Sleep to prevent spamming the heal action too fast
                Sleep($pottimer)
            Else
                ConsoleWrite("Error: Game window handle is invalid or not found." & @CRLF)
            EndIf
        EndIf
    EndIf

    ; Update the GUI labels
    GUICtrlSetData($SliderLabel, "Heal if HP below: " & $SliderValue & "%")

    Sleep($RefreshRate)
WEnd
