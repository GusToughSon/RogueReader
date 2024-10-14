#include "NomadMemory.au3"
#include <GUIConstantsEx.au3>
#include <Misc.au3>
#include <File.au3>

; Define the game process and memory offsets
$ProcessName = "Project Rogue Client.exe"
$TypeOffset = 0xBEEA34 ; Memory offset for Type
$AttackModeOffset = 0xAC0D60 ; Memory offset for Attack Mode
$PosXOffset = 0xBF1C6C ; Memory offset for Pos X
$PosYOffset = 0xBF1C64 ; Memory offset for Pos Y
$HPOffset = 0x9BE988 ; Memory offset for HP
$MaxHPOffset = 0x9BE98C ; Memory offset for MaxHP

; Pot timer (pottimer) set to 2000 ms
Global $pottimer = 2000

; Create the GUI with the title "RogueReader" and position it at X=15, Y=15
$Gui = GUICreate("RogueReader", 450, 500, 15, 15) ; Width = 450, Height = 500, X = 15, Y = 15
$TypeLabel = GUICtrlCreateLabel("Type: N/A", 20, 30, 250, 20)
$AttackModeLabel = GUICtrlCreateLabel("Attack Mode: N/A", 20, 60, 250, 20)
$PosXLabel = GUICtrlCreateLabel("Pos X: N/A", 20, 90, 250, 20)
$PosYLabel = GUICtrlCreateLabel("Pos Y: N/A", 20, 120, 250, 20)
$HPLabel = GUICtrlCreateLabel("HP: N/A", 20, 150, 250, 20)
$HP2Label = GUICtrlCreateLabel("HP2: N/A", 20, 180, 250, 20)
$MaxHPLabel = GUICtrlCreateLabel("MaxHP: N/A", 20, 210, 250, 20)
$HealerLabel = GUICtrlCreateLabel("Healer: OFF", 20, 240, 250, 20)
$HotkeyLabel = GUICtrlCreateLabel("Hotkey: ", 20, 270, 250, 20)
$PotsNote = GUICtrlCreateLabel("Pots go in #2", 20, 300, 250, 20)
$MapLabel = GUICtrlCreateLabel("Map: Off", 20, 340, 250, 20)
$MapButton = GUICtrlCreateButton("Toggle Map", 300, 340, 100, 20)
$MapLogButton = GUICtrlCreateButton("Map", 20, 380, 100, 30)
$KillButton = GUICtrlCreateButton("Kill Rogue", 140, 380, 100, 30)
$ExitButton = GUICtrlCreateButton("Exit", 260, 380, 100, 30)
GUISetState(@SW_SHOW)

; Healer toggle variable
Global $HealerStatus = False
Global $MapStatus = False ; Map toggle variable

; Get the process ID
$ProcessID = ProcessExists($ProcessName)
If $ProcessID Then
    ; Open the process memory
    $MemOpen = _MemoryOpen($ProcessID)

    ; Get the base address of the module using EnumProcessModules
    $BaseAddress = _EnumProcessModules($MemOpen)
    If $BaseAddress = 0 Then
        MsgBox(0, "Error", "Failed to get base address")
        Exit
    EndIf

    ; Calculate the target addresses by adding the offsets to the base address
    $TypeAddress = $BaseAddress + $TypeOffset
    $AttackModeAddress = $BaseAddress + $AttackModeOffset
    $PosXAddress = $BaseAddress + $PosXOffset
    $PosYAddress = $BaseAddress + $PosYOffset
    $HPAddress = $BaseAddress + $HPOffset
    $MaxHPAddress = $BaseAddress + $MaxHPOffset

    ; Main loop for the GUI and memory reading
    While 1
        $msg = GUIGetMsg()

        ; Check if the hotkey is pressed to toggle the Healer status
        If _IsPressed("C0") Then
            $HealerStatus = Not $HealerStatus
            If $HealerStatus Then
                GUICtrlSetData($HealerLabel, "Healer: ON")
            Else
                GUICtrlSetData($HealerLabel, "Healer: OFF")
            EndIf
            Sleep(300) ; Prevent rapid toggling
        EndIf

        ; Toggle the Map status when the MapButton is pressed
        If $msg = $MapButton Then
            $MapStatus = Not $MapStatus
            If $MapStatus Then
                GUICtrlSetData($MapLabel, "Map: Debug")
            Else
                GUICtrlSetData($MapLabel, "Map: Off")
            EndIf
        EndIf

        ; Log X and Y coordinates when MapLogButton is pressed
        If $msg = $MapLogButton Then
            $PosX = _MemoryRead($PosXAddress, $MemOpen, "dword")
            $PosY = _MemoryRead($PosYAddress, $MemOpen, "dword")
            LogCoordinatesToJson($PosX, $PosY, True)
        EndIf

        ; Exit the script if the Exit button is clicked
        If $msg = $ExitButton Then
            _MemoryClose($MemOpen) ; Close memory handle
            Exit
        EndIf

        ; Kill the Rogue process if the Kill button is clicked
        If $msg = $KillButton Then
            ProcessClose($ProcessID)
            Exit
        EndIf

        ; Read the Type value
        $Type = _MemoryRead($TypeAddress, $MemOpen, "dword")
        If $Type = 0 Then
            GUICtrlSetData($TypeLabel, "Type: Player (" & $Type & ")")
        ElseIf $Type = 1 Then
            GUICtrlSetData($TypeLabel, "Type: Monster (" & $Type & ")")
        ElseIf $Type = 2 Then
            GUICtrlSetData($TypeLabel, "Type: NPC (" & $Type & ")")
        Else
            GUICtrlSetData($TypeLabel, "Type: No Target (" & $Type & ")")
        EndIf

        ; Read the Pos X value
        $PosX = _MemoryRead($PosXAddress, $MemOpen, "dword")
        GUICtrlSetData($PosXLabel, "Pos X: " & $PosX)

        ; Read the Pos Y value
        $PosY = _MemoryRead($PosYAddress, $MemOpen, "dword")
        GUICtrlSetData($PosYLabel, "Pos Y: " & $PosY)

        ; Log the coordinates as solid if they aren't shown
        If $PosX = 0 Or $PosY = 0 Then
            LogCoordinatesToJson($PosX, $PosY, False)
        EndIf

        ; Read the HP and MaxHP values
        $HP = _MemoryRead($HPAddress, $MemOpen, "dword")
        GUICtrlSetData($HPLabel, "HP: " & $HP)

        ; Calculate and display HP2 (HP / 65536)
        $HP2 = $HP / 65536
        GUICtrlSetData($HP2Label, "HP2: " & $HP2)

        $MaxHP = _MemoryRead($MaxHPAddress, $MemOpen, "dword")
        GUICtrlSetData($MaxHPLabel, "MaxHP: " & $MaxHP)

        ; If Healer is ON and HP2 is <= 95% of MaxHP, send "2" key with pottimer delay
        If $HealerStatus And $HP2 <= (0.95 * $MaxHP) Then
            ControlSend("", "", "", "2")
            Sleep($pottimer) ; Wait for pottimer (2000 ms)
        EndIf

        ; Refresh every 100 ms
        Sleep(100)
    WEnd

Else
    MsgBox(0, "Error", "Project Rogue Client.exe not found.")
EndIf

; Clean up GUI on exit
GUIDelete($Gui)

; Function to log X and Y coordinates to a JSON-like file
Func LogCoordinatesToJson($x, $y, $isPassable)
    Local $jsonFile = @ScriptDir & "\coordinates.json"
    Local $fileContents = ""

    ; Check if file exists and read its contents
    If FileExists($jsonFile) Then
        $fileContents = FileRead($jsonFile)
    EndIf

    ; Prepare new entry for X and Y coordinates
    Local $status = $isPassable ? "passable" : "solid"
    Local $entry = '{ "X": ' & $x & ', "Y": ' & $y & ', "status": "' & $status & '" },' & @CRLF

    ; Append the new entry to the file
    FileWrite($jsonFile, $fileContents & $entry)
EndFunc

; Function to get the base address using EnumProcessModules
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
