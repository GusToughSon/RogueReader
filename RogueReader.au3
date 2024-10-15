#include "NomadMemory.au3"
#include <GUIConstantsEx.au3>
#include <Misc.au3>
#include <File.au3>

Global $pottimer = 2000
Global $DebugMode = False ; Debug mode is now set to False by default
Global $configFile = @ScriptDir & "\config.ini" ; Path to the config file

; Check if the config file exists, if not, create it and set default slider value to 95
If Not FileExists($configFile) Then
    IniWrite($configFile, "Settings", "HealPercentage", "95")
EndIf

; Read the slider value from the config file
$SliderValue = IniRead($configFile, "Settings", "HealPercentage", "95")

; Create the GUI
$Gui = GUICreate("RogueReader", 450, 550, 15, 15)
$TypeLabel = GUICtrlCreateLabel("Type: N/A", 20, 30, 250, 20)
$AttackModeLabel = GUICtrlCreateLabel("Attack Mode: N/A", 20, 60, 250, 20)
$PosXLabel = GUICtrlCreateLabel("Pos X: N/A", 20, 90, 250, 20)
$PosYLabel = GUICtrlCreateLabel("Pos Y: N/A", 20, 120, 250, 20)
$HPLabel = GUICtrlCreateLabel("HP: N/A", 20, 150, 250, 20)
$HP2Label = GUICtrlCreateLabel("HP2: N/A", 20, 180, 250, 20)
$MaxHPLabel = GUICtrlCreateLabel("MaxHP: N/A", 20, 210, 250, 20)
$HealerLabel = GUICtrlCreateLabel("Healer: OFF", 20, 240, 250, 20)
$HotkeyLabel = GUICtrlCreateLabel("Hotkey: `", 20, 270, 250, 20)
$PotsNote = GUICtrlCreateLabel("Pots go in #2", 20, 300, 250, 20)

$SliderLabel = GUICtrlCreateLabel("Heal if HP below: " & $SliderValue & "%", 20, 330, 250, 20) ; Label for slider
$Slider = GUICtrlCreateSlider(20, 360, 200, 30) ; Slider for dynamic healing percentage
GUICtrlSetLimit($Slider, 100, 50) ; Set slider range (50% to 100%)
GUICtrlSetData($Slider, $SliderValue) ; Set slider value from config

$KillButton = GUICtrlCreateButton("Kill Rogue", 20, 400, 100, 30)
$ExitButton = GUICtrlCreateButton("Exit", 150, 400, 100, 30)
GUISetState(@SW_SHOW)

Global $HealerStatus = False

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
    $PosXAddress = $BaseAddress + 0xBF1C6C
    $PosYAddress = $BaseAddress + 0xBF1C64
    $HPAddress = $BaseAddress + 0x9BE988
    $MaxHPAddress = $BaseAddress + 0x9BE98C

    While 1
        $msg = GUIGetMsg()

        ; Check for exit button or kill button actions
        Select
            Case $msg = $ExitButton
                ; Save the slider value to the config file before exiting
                IniWrite($configFile, "Settings", "HealPercentage", GUICtrlRead($Slider))
                _MemoryClose($MemOpen)
                Exit
            Case $msg = $KillButton
                ProcessClose($ProcessID)
                Exit
        EndSelect

        If _IsPressed("C0") Then
            $HealerStatus = Not $HealerStatus
            GUICtrlSetData($HealerLabel, "Healer: " & ($HealerStatus ? "ON" : "OFF"))
            Sleep(300)
        EndIf

        ; Update the slider percentage label dynamically
        $SliderValue = GUICtrlRead($Slider)
        GUICtrlSetData($SliderLabel, "Heal if HP below: " & $SliderValue & "%")

        ; Reading memory for Type and Attack Mode
        $Type = _MemoryRead($TypeAddress, $MemOpen, "dword")
        $AttackMode = _MemoryRead($AttackModeAddress, $MemOpen, "dword")

        Switch $Type
            Case 0
                GUICtrlSetData($TypeLabel, "Type: Player")
            Case 1
                GUICtrlSetData($TypeLabel, "Type: Monster")
            Case 2
                GUICtrlSetData($TypeLabel, "Type: NPC")
            Case Else
                GUICtrlSetData($TypeLabel, "Type: No Target (" & $Type & ")") ; Display value after Type
        EndSwitch

        ; Attack Mode status update
        GUICtrlSetData($AttackModeLabel, "Attack Mode: " & ($AttackMode ? "Attack" : "Safe"))

        ; If Attack Mode is "Attack" and Type is "No Target," send "tab" to switch target, but only if Project Rogue is the active window
        If $AttackMode = 1 And $Type > 2 Then
            If WinActive("Project Rogue Client") Then
                ControlSend("", "", "", "{TAB}")
                Sleep(100)
            EndIf
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

        ; Continue healing logic, using the slider value for the dynamic heal threshold
        If $HealerStatus And $HP2 <= ($SliderValue / 100 * $MaxHP) Then
            ControlSend("", "", "", "2")
            Sleep($pottimer)
        EndIf

        Sleep(100)
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
