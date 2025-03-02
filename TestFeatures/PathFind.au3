#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Include\RogueReader.ico
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_Res_Description=Trainer for Project Rogue
#AutoIt3Wrapper_Res_Fileversion=4.0.0.9
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_ProductName=Rogue Reader
#AutoIt3Wrapper_Res_ProductVersion=4
#AutoIt3Wrapper_Res_CompanyName=Training Trainers.LLC
#AutoIt3Wrapper_Res_LegalCopyright=Use only for authorized security testing.
#AutoIt3Wrapper_Res_LegalTradeMarks=TrainingTrainersLLC
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Run_AU3Check=n
#AutoIt3Wrapper_Tidy_Stop_OnError=n
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <GUIConstantsEx.au3>
#include <File.au3>
#include <Misc.au3>
#include <WindowsConstants.au3>
#include <WinAPI.au3>
#include <Process.au3>

; ------------------------------------------------------------------------------
; Min/Max definitions (AutoIt doesn't have them built-in)
; ------------------------------------------------------------------------------
Func Min($a, $b)
    If $a < $b Then Return $a
    Return $b
EndFunc

Func Max($a, $b)
    If $a > $b Then Return $a
    Return $b
EndFunc

Opt("MouseCoordMode", 2)
;Opt("SendKeyDelay", 1)
;Opt("SendKeyDownDelay", 5)

Global $version          = FileGetVersion(@ScriptFullPath)
Global Const $locationFile   = @ScriptDir & "\Locations.ini"
Global $currentLocations = 1
Global $maxLocations     = 200
Global Const $sButtonConfigFile = @ScriptDir & "\NewButtonConfig.ini"

ConsoleWrite("Script Version: " & $version & @CRLF)

; --- Load Config Settings ---
Global $HealHotkey             = ""
Global $CureHotkey             = ""
Global $TargetHotkey           = ""
Global $ExitHotkey             = ""
Global $SaveLocationHotkey     = ""
Global $EraseLocationsHotkey   = ""
Global $MoveToLocationsHotkey  = ""

If Not FileExists($sButtonConfigFile) Then CreateButtonDefaultConfig()
LoadButtonConfig() ; Load or reload configuration settings

Global $iCurrentLocationIndex   = 0
Global $iCurrentIndex           = 0
Global $bPaused                 = True
Global $aLocations             = LoadLocations()
Global $Debug                   = False

; ------------------- PROCESS / MEMORY OFFSETS -------------------------
Global $ProcessName       = "Project Rogue Client.exe"
Global $WindowName        = "Project Rogue"
Global $TypeOffset        = 0xBE7944 ;0 = player, 1 = monster, etc
Global $AttackModeOffset  = 0xB5BBD0
Global $PosYOffset        = 0xBF9DD8
Global $PosXOffset        = 0xBF9DE0
Global $HPOffset          = 0x7C3D0
Global $MaxHPOffset       = 0x7C3D4
Global $ChattOpenOffset   = 0xB678A8
Global $SicknessOffset    = 0x7C5B4

Global $currentTime       = TimerInit()
Global $elapsedTime       = TimerDiff($currentTime)
Global $LastHealTime      = TimerInit()
Global $elapsedTimeSinceHeal = TimerDiff($LastHealTime)
Global $MovementTime      = TimerInit()
Global $lastX             = 0
Global $lastY             = 0
Global $timer             = TimerInit()
Global $Running           = True
Global $HealerStatus      = 0
Global $CureStatus        = 0
Global $TargetStatus      = 0
Global $MoveToLocationsStatus = 0
Global $iPrevValue        = 95
Global $MPrevValue        = " "
Global $hProcess          = 0
Global $BaseAddress       = 0
Global $PosXOld           = -1
Global $PosYOld           = -1
Global $TypeAddress, $AttackModeAddress, $PosXAddress, $PosYAddress
Global $HPAddress, $MaxHPAddress, $ChattOpenAddress, $SicknessAddress
Global $Type, $Chat, $Sickness, $AttackMode
Global $SicknessDescription = GetSicknessDescription(0)

Global $sicknessArray = [ _
    1, 2, 65, 66, 67, 68, 69, 72, 73, 81, 97, 98, 99, 513, 514, 515, 577, _
    8193, 8194, 8195, 8257, 8258, 8705, 8706, 8707, 8708, 8709, 8712, 8713, _
    8721, 8737, 8769, 8770, 16385, 16386, 16449, 16450, 16451, 16452, 16897, _
    16898, 24577, 24578, 24579, 24581, 24582, 24583, 24585, 24609, 24641, _
    24642, 24643, 24645, 24646, 24647, 24649, 25089, 25090, 25091, 25093, _
    25094, 25095, 25097, 25121, 33283, 33284, 33285, 33286, 33287, 33288, _
    33289, 33291, 33293, 33294, 33295, 33793, 41985, 41986, 41987, 41988, _
    41989, 41990, 41991, 41993, 41995]

Global $TargetDelay = 400, $HealDelay = 1700
Global $aMousePos   = MouseGetPos()

; -------------------------------------------------------------------------
; BLOCKED TILE FILE (INI) + dictionary
; -------------------------------------------------------------------------
Global $g_sBlockedTilesFile = @ScriptDir & "\BlockedTiles.ini"
Global $g_tBlockedCache     = ObjCreate("Scripting.Dictionary")

; Load blocked tiles from INI into memory
Func _LoadAllBlockedTiles()
    $g_tBlockedCache.RemoveAll()
    If Not FileExists($g_sBlockedTilesFile) Then Return

    Local $aSections = IniReadSectionNames($g_sBlockedTilesFile)
    If @error Then Return

    For $i = 1 To $aSections[0]
        Local $sSectionName = $aSections[$i]
        Local $aKeys       = IniReadSection($g_sBlockedTilesFile, $sSectionName)
        If @error Then ContinueLoop

        For $k = 1 To $aKeys[0][0]
            Local $sKey = $aKeys[$k][0]
            If StringLeft($sKey, 5) = "Tile_" Then
                Local $aSplit = StringSplit(StringTrimLeft($sKey, 5), "_")
                If UBound($aSplit) = 3 Then
                    Local $iX = Number($aSplit[1])
                    Local $iY = Number($aSplit[2])
                    $g_tBlockedCache.Item($iX & "_" & $iY) = True
                EndIf
            EndIf
        Next
    Next
EndFunc

Func _IsTileBlocked($x, $y)
    Return $g_tBlockedCache.Exists($x & "_" & $y)
EndFunc

Func _MarkTileBlocked($x, $y)
    If $x < 0 Or $y < 0 Then Return
    If _IsTileBlocked($x, $y) Then Return

    $g_tBlockedCache.Item($x & "_" & $y) = True
    Local $cx       = Floor($x / 16)
    Local $cy       = Floor($y / 16)
    Local $sSection = "Chunk_" & $cx & "_" & $cy
    Local $sKey     = "Tile_" & $x & "_" & $y

    IniWrite($g_sBlockedTilesFile, $sSection, $sKey, 1)
    ConsoleWrite(">>> Marked tile BLOCKED at X=" & $x & " Y=" & $y & " in section [" & $sSection & "]" & @CRLF)
EndFunc

; --------------------------------------------------------------------------
; CREATE GUI
; --------------------------------------------------------------------------
Global $Gui = GUICreate("RougeReader Version - " & $version, 400, 400, 15, 15)
Global $TypeLabel       = GUICtrlCreateLabel("Type: N/A", 20, 30, 250, 20)
Global $AttackModeLabel = GUICtrlCreateLabel("Attack Mode: N/A", 20, 60, 250, 20)
Global $PosXLabel       = GUICtrlCreateLabel("Pos X: N/A", 20, 90, 250, 20)
Global $PosYLabel       = GUICtrlCreateLabel("Pos Y: N/A", 20, 120, 250, 20)
Global $HPLabel         = GUICtrlCreateLabel("HP: N/A", 20, 150, 250, 20)
Global $ChatLabel       = GUICtrlCreateLabel("Chat: N/A", 120, 150, 250, 20)
Global $HP2Label        = GUICtrlCreateLabel("RealHp: N/A", 20, 180, 250, 20)
Global $SicknessLabel   = GUICtrlCreateLabel("Sickness: N/A", 120, 180, 250, 20)
Global $MaxHPLabel      = GUICtrlCreateLabel("MaxHP: N/A", 20, 210, 250, 20)
Global $TargetLabel     = GUICtrlCreateLabel("Target: Off", 120, 210, 250, 20)
Global $HealerLabel     = GUICtrlCreateLabel("Healer: Off", 20, 240, 250, 20)
Global $WalkerLabel     = GUICtrlCreateLabel("Walker: Off", 120, 150, 250, 20)
Global $CureLabel       = GUICtrlCreateLabel("Cure: Off", 120, 240, 250, 20)
Global $HotkeyLabel     = GUICtrlCreateLabel("Set hotkeys in the config file", 20, 270, 350, 20)
Global $KillButton      = GUICtrlCreateButton("Kill Rogue", 20, 300, 100, 30)
Global $ExitButton      = GUICtrlCreateButton("Exit", 150, 300, 100, 30)

Global $healSlider = GUICtrlCreateSlider(20, 350, 200, 20)
GUICtrlSetLimit($healSlider, 95, 45)
GUICtrlSetData($healSlider, 75)
Global $healLabel = GUICtrlCreateLabel("Heal at: 75%", 230, 350, 100, 20)

Global $MovmentSlider = GUICtrlCreateSlider(20, 370, 180, 20)
GUICtrlSetLimit($MovmentSlider, 750, 50)
GUICtrlSetData($MovmentSlider, 150)
Global $MoveLabel   = GUICtrlCreateLabel("Heal After 150", 185, 370, 100, 20)
Global $MoveLabell  = GUICtrlCreateLabel("ms of no movment.", 280, 370, 100, 20)

Global $Checkbox      = GUICtrlCreateCheckbox("Old Style Pothack", 240, 250, 200, 20)
Global $CheckboxLabel = GUICtrlCreateLabel("(Ignore Heal After)", 240, 270, 200, 20)
Global $NEW           = GUICtrlCreateLabel("*This now functions*", 240, 230, 200, 20)

GUISetState(@SW_SHOW)

; --------------------------------------------------------------------------
; MAIN STREAMLINED LOOP
; --------------------------------------------------------------------------
_LoadAllBlockedTiles() ; load any previously discovered blocked tiles

While $Running
    Local $msg = GUIGetMsg()
    Switch $msg
        Case $ExitButton, $GUI_EVENT_CLOSE
            _WinAPI_CloseHandle($hProcess)
            GUIDelete($Gui)
            ConsoleWrite("[Debug] Trainer closed" & @CRLF)
            Exit

        Case $KillButton
            Local $pidCheck = ProcessExists($ProcessName)
            If $pidCheck Then ProcessClose($pidCheck)

    EndSwitch

    ; Update slider label changes
    Local $MValue = GUICtrlRead($MovmentSlider)
    If $MValue <> $MPrevValue Then
        GUICtrlSetData($MoveLabel, "Heal After " & $MValue)
        $MPrevValue = $MValue
    EndIf

    Local $iValue = GUICtrlRead($healSlider)
    If $iValue <> $iPrevValue Then
        GUICtrlSetData($healLabel, "Heal at: " & $iValue & "%")
        $iPrevValue = $iValue
    EndIf

    ; Check if game is running
    Local $ProcessID = ProcessExists($ProcessName)
    If Not $ProcessID Then
        If $hProcess <> 0 Then
            ConsoleWrite("[Info] Game closed, handle reset..." & @CRLF)
            _WinAPI_CloseHandle($hProcess)
        EndIf
        $hProcess    = 0
        $BaseAddress = 0
        ConsoleWrite("[Info] Game not found, waiting..." & @CRLF)
        Sleep(200)
        ContinueLoop
    EndIf

    ; If game is found but handle not open
    If $hProcess = 0 Then
        ConnectToBaseAddress()
        If $BaseAddress = 0 Or $hProcess = 0 Then
            Sleep(200)
            ContinueLoop
        Else
            ChangeAddressToBase()
            ConsoleWrite("[Info] Connected to game process." & @CRLF)
        EndIf
    EndIf

    ; If we get here, process is open and we have a handle
    GUIReadMemory()

    ; If chat is closed, do Cure/Target/Healer/Walker logic
    If $Chat = 0 Then
        If $CureStatus   = 1 Then CureMe()
        If $TargetStatus = 1 Then AttackModeReader()
        If $HealerStatus = 1 Then TimeToHeal()

        If $MoveToLocationsStatus = 1 Then
            Local $result = MoveToLocationsStep($aLocations, $iCurrentIndex)
            If @error Then
                ConsoleWrite("Error or end of locations: " & @error & @CRLF)
                $MoveToLocationsStatus = 0
            EndIf
        EndIf
    EndIf

    ; Check if process is still alive
    If Not ProcessExists($ProcessID) Then
        ConsoleWrite("[Info] Game closed unexpectedly, handle reset..." & @CRLF)
        _WinAPI_CloseHandle($hProcess)
        $hProcess    = 0
        $BaseAddress = 0
    EndIf

    Sleep(100)
WEnd

GUIDelete($Gui)
_WinAPI_CloseHandle($hProcess)
ConsoleWrite("[Debug] Trainer closed by script end" & @CRLF)
Exit

; ------------------------------------------------------------------------------
;                               LOAD CONFIG
; ------------------------------------------------------------------------------
Func LoadButtonConfig()
    Local $sButtonConfigFile = @ScriptDir & "\NewButtonConfig.ini"

    ; Remove old/unused entries
    IniDelete($sButtonConfigFile, "Hotkeys", "TogglePauseHotkey")
    IniDelete($sButtonConfigFile, "Hotkeys", "PlayLocationsHotkey")

    ; Define the hotkeys and default values
    Local $aKeys[7][2] = [ _
        ["HealHotkey", "{" & Chr(96) & "}"], _
        ["CureHotkey", "{-}"], _
        ["TargetHotkey", "{=}"], _
        ["ExitHotkey", "{#}"], _
        ["SaveLocationHotkey", "{F7}"], _
        ["EraseLocationsHotkey", "{F8}"], _
        ["MoveToLocationsHotkey", "{!}"] _
    ]

    Local $bMissingKeys = False
    For $i = 0 To UBound($aKeys) - 1
        Local $sKey = IniRead($sButtonConfigFile, "Hotkeys", $aKeys[$i][0], "")
        If $sKey = "" Then
            ConsoleWrite("[Warning] Missing key: " & $aKeys[$i][0] & ". Will create default config." & @CRLF)
            $bMissingKeys = True
            ExitLoop
        EndIf
    Next

    ; If any key was missing, recreate the default configuration
    If $bMissingKeys Then
        CreateButtonDefaultConfig()
    EndIf

    ; Re-read the keys after ensuring defaults exist
    For $i = 0 To UBound($aKeys) - 1
        Local $sKey = IniRead($sButtonConfigFile, "Hotkeys", $aKeys[$i][0], $aKeys[$i][1])

        Switch $aKeys[$i][0]
            Case "HealHotkey"
                HotKeySet($sKey, "Hotkeyshit")
            Case "CureHotkey"
                HotKeySet($sKey, "CureKeyShit")
            Case "TargetHotkey"
                HotKeySet($sKey, "TargetKeyShit")
            Case "ExitHotkey"
                HotKeySet($sKey, "KilledWithFire")
            Case "SaveLocationHotkey"
                HotKeySet($sKey, "SaveLocation")
            Case "EraseLocationsHotkey"
                HotKeySet($sKey, "EraseLocations")
            Case "MoveToLocationsHotkey"
                HotKeySet($sKey, "MoveToLocations")
        EndSwitch

        ConsoleWrite("[Info] Hotkey for " & $aKeys[$i][0] & " set to " & $sKey & @CRLF)
    Next
EndFunc

Func CreateButtonDefaultConfig()
    Local $sButtonConfigFile = @ScriptDir & "\NewButtonConfig.ini"
    Local $aKeys[7][2] = [ _
        ["HealHotkey", "{" & Chr(96) & "}"], _
        ["CureHotkey", "{-}"], _
        ["TargetHotkey", "{=}"], _
        ["ExitHotkey", "{#}"], _
        ["SaveLocationHotkey", "{F7}"], _
        ["EraseLocationsHotkey", "{F8}"], _
        ["MoveToLocationsHotkey", "{!}"] _
    ]
    For $i = 0 To UBound($aKeys) - 1
        IniWrite($sButtonConfigFile, "Hotkeys", $aKeys[$i][0], $aKeys[$i][1])
    Next
    ConsoleWrite("[Info] Default ButtonConfig.ini created with hotkeys." & @CRLF)
EndFunc

; ------------------------------------------------------------------------------
;                             READ AND UPDATE GUI FROM MEMORY
; ------------------------------------------------------------------------------
Func GUIReadMemory()
    If $hProcess = 0 Then Return

    $Type = _ReadMemory($hProcess, $TypeAddress)
    If $Type = 0 Then
        GUICtrlSetData($TypeLabel, "Type: Player")
    ElseIf $Type = 1 Then
        GUICtrlSetData($TypeLabel, "Type: Monster")
    ElseIf $Type = 2 Then
        GUICtrlSetData($TypeLabel, "Type: NPC")
    ElseIf $Type = 65535 Then
        GUICtrlSetData($TypeLabel, "Type: No Target")
    Else
        GUICtrlSetData($TypeLabel, "Type: Unknown (" & $Type & ")")
    EndIf

    ; Walker
    If $MoveToLocationsStatus = 0 Then
        GUICtrlSetData($WalkerLabel, "Walker: Off")
    ElseIf $MoveToLocationsStatus = 1 Then
        GUICtrlSetData($WalkerLabel, "Walker: On")
    Else
        GUICtrlSetData($WalkerLabel, "Error: Broken")
    EndIf

    $AttackMode = _ReadMemory($hProcess, $AttackModeAddress)
    If $AttackMode = 0 Then
        GUICtrlSetData($AttackModeLabel, "Attack Mode: Safe")
    ElseIf $AttackMode = 1 Then
        GUICtrlSetData($AttackModeLabel, "Attack Mode: Attack")
    Else
        GUICtrlSetData($AttackModeLabel, "Attack Mode: No Target")
    EndIf

    Local $PosX = _ReadMemory($hProcess, $PosXAddress)
    Local $PosY = _ReadMemory($hProcess, $PosYAddress)
    GUICtrlSetData($PosXLabel, "Pos X: " & $PosX)
    GUICtrlSetData($PosYLabel, "Pos Y: " & $PosY)

    Local $HP = _ReadMemory($hProcess, $HPAddress)
    GUICtrlSetData($HPLabel, "HP: " & $HP)
    GUICtrlSetData($HP2Label, "RealHp: " & ($HP / 65536))

    Local $MaxHP = _ReadMemory($hProcess, $MaxHPAddress)
    GUICtrlSetData($MaxHPLabel, "MaxHP: " & $MaxHP)

    Local $ChatVal = _ReadMemory($hProcess, $ChattOpenAddress)
    $Chat = $ChatVal
    GUICtrlSetData($ChatLabel, "Chat: " & $ChatVal)

    Local $SickVal = _ReadMemory($hProcess, $SicknessAddress)
    $Sickness = $SickVal
    $SicknessDescription = GetSicknessDescription($SickVal)
    GUICtrlSetData($SicknessLabel, "Sickness: " & $SicknessDescription)
EndFunc

; ------------------------------------------------------------------------------
;                                 CURE FUNCTION
; ------------------------------------------------------------------------------
Func CureMe()
    If $Chat <> 0 Then
        Sleep(50)
        Return
    EndIf

    $Sickness = _ReadMemory($hProcess, $SicknessAddress)
    If _ArraySearch($sicknessArray, $Sickness) = -1 Then
        Return
    EndIf

    Local $Healwait       = GUICtrlRead($MovmentSlider)
    Local $HP             = _ReadMemory($hProcess, $HPAddress)
    Local $RealHP         = $HP / 65536
    Local $SickVal        = _ReadMemory($hProcess, $SicknessAddress)
    Local $HealThreshold  = GUICtrlRead($healSlider) / 100

    Local $CurrentX = Number(StringRegExpReplace(GUICtrlRead($PosXLabel), "[^\d]", ""))
    Local $CurrentY = Number(StringRegExpReplace(GUICtrlRead($PosYLabel), "[^\d]", ""))
    Static $LastX   = $CurrentX, $LastY = $CurrentY

    $elapsedTimeSinceHeal = TimerDiff($LastHealTime)
    ConsoleWrite("Cure check initiated... HP=" & $RealHP & "  Sickness=" & $SickVal & @CRLF)

    If $CurrentX <> $LastX Or $CurrentY <> $LastY Then
        If GUICtrlRead($Checkbox) <> $GUI_CHECKED Then
            ConsoleWrite("Movement detected, resetting movement timer for Cure." & @CRLF)
            $LastX = $CurrentX
            $LastY = $CurrentY
            $MovementTime = TimerInit()
        EndIf
    EndIf

    If GUICtrlRead($Checkbox) = $GUI_CHECKED Then
        If $elapsedTimeSinceHeal >= $HealDelay Then
            ControlSend("Project Rogue", "", "", "{3}")
            ConsoleWrite("Cure triggered (old style)" & @CRLF)
            $LastHealTime = TimerInit()
        EndIf
    Else
        If $elapsedTimeSinceHeal >= $HealDelay Then
            If TimerDiff($MovementTime) > $Healwait Then
                ControlSend("Project Rogue", "", "", "{3}")
                ConsoleWrite("Cure triggered: no movement for " & $Healwait & " ms." & @CRLF)
                $LastHealTime = TimerInit()
            Else
                ConsoleWrite("Cure NOT triggered: waiting no-movement. " & TimerDiff($MovementTime) & " ms so far." & @CRLF)
            EndIf
        EndIf
    EndIf
EndFunc

; ------------------------------------------------------------------------------
;                                 HEALER
; ------------------------------------------------------------------------------
Func TimeToHeal()
    Local $Healwait      = GUICtrlRead($MovmentSlider)
    Local $HP            = _ReadMemory($hProcess, $HPAddress)
    Local $RealHP        = $HP / 65536
    Local $MaxHP         = _ReadMemory($hProcess, $MaxHPAddress)
    Local $ChatVal       = _ReadMemory($hProcess, $ChattOpenAddress)
    Local $HealThreshold = GUICtrlRead($healSlider) / 100

    Local $CurrentX = Number(StringRegExpReplace(GUICtrlRead($PosXLabel), "[^\d]", ""))
    Local $CurrentY = Number(StringRegExpReplace(GUICtrlRead($PosYLabel), "[^\d]", ""))
    Static $LastX   = $CurrentX, $LastY = $CurrentY

    $elapsedTimeSinceHeal = TimerDiff($LastHealTime)
    ConsoleWrite("TimeToHeal() check. HP=" & $RealHP & "/" & $MaxHP & " threshold=" & $HealThreshold & @CRLF)

    If $CurrentX <> $LastX Or $CurrentY <> $LastY Then
        If GUICtrlRead($Checkbox) <> $GUI_CHECKED Then
            ConsoleWrite("Movement detected, resetting movement timer for Heal." & @CRLF)
            $LastX = $CurrentX
            $LastY = $CurrentY
            $MovementTime = TimerInit()
        EndIf
    EndIf

    If GUICtrlRead($Checkbox) = $GUI_CHECKED Then
        If $ChatVal = 0 And _ArraySearch($sicknessArray, $Sickness) = -1 Then
            If $RealHP < ($MaxHP * $HealThreshold) Then
                If $elapsedTimeSinceHeal > $HealDelay Then
                    ControlSend("Project Rogue", "", "", "{2}")
                    ConsoleWrite("Heal triggered (old style): HP < threshold" & @CRLF)
                    $LastHealTime = TimerInit()
                EndIf
            EndIf
        EndIf
    Else
        If $ChatVal = 0 And _ArraySearch($sicknessArray, $Sickness) = -1 _
                And $elapsedTimeSinceHeal >= $HealDelay Then
            If $RealHP < ($MaxHP * $HealThreshold) Then
                If TimerDiff($MovementTime) > $Healwait Then
                    ControlSend("Project Rogue", "", "", "{2}")
                    ConsoleWrite("Healed: HP < threshold + no movement." & @CRLF)
                    $LastHealTime = TimerInit()
                Else
                    ConsoleWrite("No heal: movement timer not past " & $Healwait & " ms." & @CRLF)
                EndIf
            EndIf
        EndIf
    EndIf
EndFunc

; ------------------------------------------------------------------------------
;                                 TARGETING
; ------------------------------------------------------------------------------
Func AttackModeReader()
    $ChatVal    = _ReadMemory($hProcess, $ChattOpenAddress)
    $Chat       = $ChatVal
    $AttackMode = _ReadMemory($hProcess, $AttackModeAddress)

    If $AttackMode = 0 Then
        GUICtrlSetData($AttackModeLabel, "Attack Mode: Safe")
    ElseIf $AttackMode = 1 Then
        GUICtrlSetData($AttackModeLabel, "Attack Mode: Attack")
        ; You can add extra logic if needed here
    Else
        GUICtrlSetData($AttackModeLabel, "Attack Mode: No Target")
    EndIf
EndFunc

Func ConnectToBaseAddress()
    $hProcess = _WinAPI_OpenProcess(0x1F0FFF, False, $ProcessID)
    If $hProcess = 0 Then
        ConsoleWrite("[Error] Failed to open process! Try running as administrator." & @CRLF)
        Return
    EndIf
    $BaseAddress = _GetModuleBase_EnumModules($hProcess)
    If $BaseAddress = 0 Then
        ConsoleWrite("[Error] Failed to obtain a valid base address!" & @CRLF)
    EndIf
EndFunc

Func ChangeAddressToBase()
    $TypeAddress       = $BaseAddress + $TypeOffset
    $AttackModeAddress = $BaseAddress + $AttackModeOffset
    $PosXAddress       = $BaseAddress + $PosXOffset
    $PosYAddress       = $BaseAddress + $PosYOffset
    $HPAddress         = $BaseAddress + $HPOffset
    $MaxHPAddress      = $BaseAddress + $MaxHPOffset
    $ChattOpenAddress  = $BaseAddress + $ChattOpenOffset
    $SicknessAddress   = $BaseAddress + $SicknessOffset
EndFunc

Func _GetModuleBase_EnumModules($hProcess)
    Local $hPsapi = DllOpen("psapi.dll")
    If $hPsapi = 0 Then Return 0

    Local $tModules     = DllStructCreate("ptr[1024]")
    Local $tBytesNeeded = DllStructCreate("dword")
    Local $aCall        = DllCall("psapi.dll", "bool", "EnumProcessModules", _
                                   "handle", $hProcess, _
                                   "ptr", DllStructGetPtr($tModules), _
                                   "dword", DllStructGetSize($tModules), _
                                   "ptr", DllStructGetPtr($tBytesNeeded))
    If @error Or Not $aCall[0] Then
        DllClose($hPsapi)
        Return 0
    EndIf
    Local $pBaseAddress = DllStructGetData($tModules, 1, 1)
    DllClose($hPsapi)
    Return $pBaseAddress
EndFunc

Func _ReadMemory($hProcess, $pAddress)
    If $hProcess = 0 Or $pAddress = 0 Then Return 0

    Local $tBuffer = DllStructCreate("dword")
    Local $aRead   = DllCall("kernel32.dll", "bool", "ReadProcessMemory", _
                             "handle", $hProcess, _
                             "ptr", $pAddress, _
                             "ptr", DllStructGetPtr($tBuffer), _
                             "dword", DllStructGetSize($tBuffer), _
                             "ptr", 0)
    If @error Or Not $aRead[0] Then Return 0
    Return DllStructGetData($tBuffer, 1)
EndFunc

; --------------------------------------------------------------------------
; HOTKEY TOGGLE FUNCTIONS
; --------------------------------------------------------------------------
Func Hotkeyshit()
    $HealerStatus = Not $HealerStatus
    GUICtrlSetData($HealerLabel, "Healer: " & ($HealerStatus ? "On" : "Off"))
    Sleep(300)
EndFunc

Func CureKeyShit()
    $CureStatus = Not $CureStatus
    GUICtrlSetData($CureLabel, "Cure: " & ($CureStatus ? "On" : "Off"))
    Sleep(300)
EndFunc

Func TargetKeyShit()
    $TargetStatus = Not $TargetStatus
    GUICtrlSetData($TargetLabel, "Target: " & ($TargetStatus ? "On" : "Off"))
    Sleep(300)
EndFunc

Func KilledWithFire()
    If $Debug Then ConsoleWrite("Killed with fire" & @CRLF)
    Exit
EndFunc

; --------------------------------------------------------------------------
; Return a more human label for some “Sick” codes
; --------------------------------------------------------------------------
Func GetSicknessDescription($Sick)
    Local $SicknessDescription = "Unknown"
    Switch $Sick
        Case 1
            $SicknessDescription = "Poison1 (" & $Sick & ")"
        Case 2
            $SicknessDescription = "Disease1 (" & $Sick & ")"
        ; Add more if you wish
        Case Else
            $SicknessDescription = $Sick
    EndSwitch
    Return $SicknessDescription
EndFunc

; ------------------------------------------------------------------------------
; LOCATION LOADING
; ------------------------------------------------------------------------------
Func LoadLocations()
    Local $iMaxLocations = 200
    If Not FileExists($locationFile) Then
        ConsoleWrite("[Error] Location file not found: " & $locationFile & @CRLF)
        Return SetError(1, 0, 0)
    EndIf

    Local $aLines = FileReadToArray($locationFile)
    If @error Then
        ConsoleWrite("[Error] Failed to read file: " & $locationFile & @CRLF)
        Return SetError(2, 0, 0)
    EndIf

    Local $iLocationCount = 0
    Dim $aTempLocations[UBound($aLines)][2]

    For $i = 0 To UBound($aLines) - 1
        Local $aMatches = StringRegExp($aLines[$i], "X:(\d+);Y:(\d+)", 3)
        If Not @error And UBound($aMatches) = 2 Then
            $aTempLocations[$iLocationCount][0] = Int($aMatches[0])
            $aTempLocations[$iLocationCount][1] = Int($aMatches[1])
            $iLocationCount += 1
        Else
            ConsoleWrite("[Warning] Failed to parse line " & $i & ": " & $aLines[$i] & @CRLF)
        EndIf
    Next

    If $iLocationCount = 0 Then
        ConsoleWrite("[Warning] No valid locations found in " & $locationFile & @CRLF)
        Return SetError(3, 0, 0)
    EndIf

    ReDim $aTempLocations[$iLocationCount][2]
    ConsoleWrite("[Success] Loaded " & $iLocationCount & " locations." & @CRLF)
    Return $aTempLocations
EndFunc

Func SaveLocation()
    Local $x = _ReadMemory($hProcess, $PosXAddress)
    Local $y = _ReadMemory($hProcess, $PosYAddress)
    ConsoleWrite("Attempting to read X: " & $x & " Y: " & $y & @CRLF)

    If @error Then
        ConsoleWrite("[Error] Failed to read memory. Error code: " & @error & @CRLF)
        Return
    EndIf
    If $x == 0 And $y == 0 Then
        ConsoleWrite("[Warning] Read zero for both coordinates. Possible bad read." & @CRLF)
        Return
    EndIf

    If Not FileExists($locationFile) Then
        Local $file = FileOpen($locationFile, $FO_CREATEPATH + $FO_OVERWRITE)
        If $file == -1 Then
            ConsoleWrite("[Error] Failed to create file: " & $locationFile & @CRLF)
            Return
        EndIf
        FileClose($file)
        ConsoleWrite("[Info] File created: " & $locationFile & @CRLF)
    EndIf

    Local $data = " : Location" & $currentLocations & "=X:" & $x & ";Y:" & $y & @CRLF
    If $currentLocations < $maxLocations Then
        _FileWriteLog($locationFile, $data)
        If @error Then
            ConsoleWrite("[Error] Failed to write to file: " & $locationFile & @CRLF)
        Else
            ConsoleWrite("[Info] Data written: " & $data)
            $currentLocations += 1
        EndIf
    Else
        ConsoleWrite("[Info] Maximum locations reached. Stop pressing the button!" & @CRLF)
    EndIf
EndFunc

Func EraseLocations()
    FileDelete($locationFile)
    $currentLocations = 1
    ConsoleWrite("Success - All locations erased." & @CRLF)
EndFunc

; ------------------------------------------------------------------------------
;  BFS-BASED LOCATION WALKING WITH RANDOM ±2 OFFSET
; ------------------------------------------------------------------------------
Func MoveToLocations()
    If $MoveToLocationsStatus = 0 Then
        ; Turn on
        Local $currentX = _ReadMemory($hProcess, $PosXAddress)
        Local $currentY = _ReadMemory($hProcess, $PosYAddress)
        $iCurrentIndex  = FindClosestLocationIndex($currentX, $currentY, $aLocations)

        If $iCurrentIndex = -1 Then
            ConsoleWrite("[Error] Could not find a closest location index (no valid data?)." & @CRLF)
            Return
        EndIf
        $MoveToLocationsStatus = 1
        ConsoleWrite("move on" & @CRLF)
    ElseIf $MoveToLocationsStatus = 1 Then
        ; Turn off
        $MoveToLocationsStatus = 0
        ConsoleWrite("move off" & @CRLF)
    Else
        MsgBox(0, "Error", "You shouldn't have gotten this error", 5)
    EndIf
EndFunc

; ------------------------------------------------------------------------------
; MoveToLocationsStep() with random ±2 offset, stops if target is found
; ------------------------------------------------------------------------------
Func MoveToLocationsStep($aLocations, ByRef $iCurrentIndex)
    If Not IsArray($aLocations) Then
        ConsoleWrite("Error: $aLocations is not an array." & @CRLF)
        Return SetError(1, 0, "Invalid input")
    EndIf
    If $iCurrentIndex < 0 Or $iCurrentIndex >= UBound($aLocations) Then
        ConsoleWrite("Error: Invalid or out-of-range index: " & $iCurrentIndex & @CRLF)
        Return SetError(2, 0, "Index out of range")
    EndIf

    Local $origX    = $aLocations[$iCurrentIndex][0]
    Local $origY    = $aLocations[$iCurrentIndex][1]
    Local $currentX = _ReadMemory($hProcess, $PosXAddress)
    Local $currentY = _ReadMemory($hProcess, $PosYAddress)
    Local $Type     = _ReadMemory($hProcess, $TypeAddress)

    ConsoleWrite("MoveToLocationsStep: current=(" & $currentX & "," & $currentY & _
        ") => original waypoint=(" & $origX & "," & $origY & ")" & @CRLF)

    ; Only move if Type=65535 => no target
    If $Type <> 65535 Then
        ConsoleWrite("Movement paused. We have a target => " & $Type & @CRLF)
        Return False
    EndIf

    ; If already exactly at that location, skip
    If $currentX = $origX And $currentY = $origY Then
        ConsoleWrite("Arrived exactly at location " & ($iCurrentIndex + 1) & _
            " => (X=" & $origX & ", Y=" & $origY & ")." & @CRLF)
        $iCurrentIndex += 1
        If $iCurrentIndex >= UBound($aLocations) Then
            $iCurrentIndex = 0
        EndIf
        Return True
    EndIf

    ; 1) Build a random list of all tiles within ±2
    Local $aCandidates = _GenerateRandomOffsets($origX, $origY, 2)
    If UBound($aCandidates, 1) = 0 Then
        ConsoleWrite("No candidate tiles??" & @CRLF)
        Return False
    EndIf

    Local $foundPath = False
    Local $finalX, $finalY

    ; 2) Try each candidate tile
    For $i = 0 To UBound($aCandidates) - 1
        $finalX = $aCandidates[$i][0]
        $finalY = $aCandidates[$i][1]

        If _IsTileBlocked($finalX, $finalY) Then
            ConsoleWrite("Candidate (" & $finalX & "," & $finalY & ") is known blocked => skipping." & @CRLF)
            ContinueLoop
        EndIf

        ConsoleWrite("Trying candidate tile: (" & $finalX & "," & $finalY & ")" & @CRLF)

        Local $aPath = _BFS_FindPath($currentX, $currentY, $finalX, $finalY)
        If UBound($aPath, 1) = 0 Then
            ConsoleWrite("No BFS path => skipping candidate." & @CRLF)
            ContinueLoop
        EndIf

        Local $res = _WalkBFSPath($aPath)
        If $res Then
            $foundPath = True
            ExitLoop
        Else
            ConsoleWrite("Candidate BFS stepping failed => try next tile." & @CRLF)
        EndIf
    Next

    If Not $foundPath Then
        ConsoleWrite("All ±2 offset tiles for (" & $origX & "," & $origY & ") failed => skipping location." & @CRLF)
        $iCurrentIndex += 1
        If $iCurrentIndex >= UBound($aLocations) Then
            $iCurrentIndex = 0
        EndIf
        Return False
    EndIf

    ConsoleWrite("Arrived near location " & ($iCurrentIndex + 1) & _
        " => random tile (X=" & $finalX & ", Y=" & $finalY & ")." & @CRLF)

    $iCurrentIndex += 1
    If $iCurrentIndex >= UBound($aLocations) Then
        $iCurrentIndex = 0
    EndIf
    Return True
EndFunc

; ------------------------------------------------------------------------------
; BFS + BLOCKED TILE CHECK
; ------------------------------------------------------------------------------
Func _BFS_FindPath($sx, $sy, $tx, $ty)
    If $sx = $tx And $sy = $ty Then
        Local $aPath2[1][2] = [[$sx, $sy]]
        Return $aPath2
    EndIf

    ; smaller bounding box => ±10
    Local $minX = Min($sx, $tx) - 10
    Local $maxX = Max($sx, $tx) + 10
    Local $minY = Min($sy, $ty) - 10
    Local $maxY = Max($sy, $ty) + 10
    If $minX < 0 Then $minX = 0
    If $minY < 0 Then $minY = 0

    Local $queue[1][2] = [[$sx, $sy]]
    Local $head = 0, $tail = 1

    Local $visited = ObjCreate("Scripting.Dictionary")
    $visited.Item($sx & "_" & $sy) = True

    Local $parent = ObjCreate("Scripting.Dictionary")

    While $head < $tail
        Local $cx = $queue[$head][0]
        Local $cy = $queue[$head][1]
        $head += 1

        Local $neighbors[4][2] = [ _
            [$cx, $cy - 1], _
            [$cx, $cy + 1], _
            [$cx - 1, $cy], _
            [$cx + 1, $cy] ]

        For $i = 0 To 3
            Local $nx = $neighbors[$i][0]
            Local $ny = $neighbors[$i][1]

            If $nx < $minX Or $nx > $maxX Or $ny < $minY Or $ny > $maxY Then ContinueLoop
            If $visited.Exists($nx & "_" & $ny) Then ContinueLoop
            If _IsTileBlocked($nx, $ny) Then ContinueLoop

            _ArrayAdd2D_BFS($queue, $nx, $ny, $tail)
            $tail += 1
            $visited.Item($nx & "_" & $ny) = True

            Local $temp[2]
            $temp[0] = $cx
            $temp[1] = $cy
            $parent.Item($nx & "_" & $ny) = $temp

            If $nx = $tx And $ny = $ty Then
                Return _BFS_ReconstructPath($sx, $sy, $tx, $ty, $parent)
            EndIf
        Next
    WEnd

    Local $noPath[0][2]
    Return $noPath
EndFunc

Func _BFS_ReconstructPath($sx, $sy, $tx, $ty, ByRef $parent)
    Local $revPath[0][2]
    Local $cx = $tx
    Local $cy = $ty

    While Not($cx = $sx And $cy = $sy)
        _ArrayPrepend2D($revPath, $cx, $cy)
        Local $p = $parent.Item($cx & "_" & $cy)
        Local $px = $p[0]
        Local $py = $p[1]
        $cx = $px
        $cy = $py
    WEnd
    _ArrayPrepend2D($revPath, $sx, $sy)
    Return $revPath
EndFunc

; ------------------------------------------------------------------------------
; STEPPING THE BFS PATH, if we see a target, we bail.
; ------------------------------------------------------------------------------
Func _WalkBFSPath($aPath)
    If UBound($aPath, 1) < 2 Then
        ; trivial
        Return True
    EndIf

    Local $stepIndex = 1
    While True
        ; Let user stop the walker any time
        If $MoveToLocationsStatus = 0 Then
            ConsoleWrite("Walker turned OFF mid BFS stepping => returning False." & @CRLF)
            Return False
        EndIf

        ; *** NEW: We check AttackMode & Type to “target faster” ***
        ; 1) Read AttackMode & Type
        Local $attackModeVal = _ReadMemory($hProcess, $AttackModeAddress)
        Local $typeVal       = _ReadMemory($hProcess, $TypeAddress)

        If $attackModeVal = 1 Then
            ; if we want to attack, but have no target => attempt Tab
            If $typeVal = 65535 Then
                ControlSend($WindowName, "", "", "{TAB}")
                Sleep(50)
                ; re-read type
                $typeVal = _ReadMemory($hProcess, $TypeAddress)
            EndIf

            ; if we do find a target now => STOP BFS
            If $typeVal <> 65535 Then
                ConsoleWrite("Found target => stopping BFS stepping." & @CRLF)
                Return False
            EndIf
        EndIf

        ; if done BFS steps
        If $stepIndex >= UBound($aPath, 1) Then
            ExitLoop
        EndIf

        Local $stepX = $aPath[$stepIndex][0]
        Local $stepY = $aPath[$stepIndex][1]

        ConsoleWrite("-> BFS step: (" & $stepX & "," & $stepY & ")" & @CRLF)

        Local $bSuccess = AttemptMoveToTile($stepX, $stepY, 3)
        If Not $bSuccess Then
            ConsoleWrite("Could not move => BFS stepping fails. Mark tile blocked." & @CRLF)
            _MarkTileBlocked($stepX, $stepY)
            Return False
        EndIf

        $stepIndex += 1

        ; let GUI remain responsive, process hotkeys quickly
        GUIGetMsg(0)
        Sleep(25)
    WEnd

    Return True
EndFunc

; ------------------------------------------------------------------------------
; Attempt a single tile movement
; ------------------------------------------------------------------------------
Func AttemptMoveToTile($tx, $ty, $maxTries = 3)
    For $try = 1 To $maxTries
        Local $cx = _ReadMemory($hProcess, $PosXAddress)
        Local $cy = _ReadMemory($hProcess, $PosYAddress)
        If $cx = $tx And $cy = $ty Then Return True

        ; Move horizontally
        If $cx < $tx Then
            ControlSend($WindowName, "", "", "{d down}")
            Sleep(30)
            ControlSend($WindowName, "", "", "{d up}")
        ElseIf $cx > $tx Then
            ControlSend($WindowName, "", "", "{a down}")
            Sleep(30)
            ControlSend($WindowName, "", "", "{a up}")
        EndIf

        ; Move vertically
        If $cy < $ty Then
            ControlSend($WindowName, "", "", "{s down}")
            Sleep(30)
            ControlSend($WindowName, "", "", "{s up}")
        ElseIf $cy > $ty Then
            ControlSend($WindowName, "", "", "{w down}")
            Sleep(30)
            ControlSend($WindowName, "", "", "{w up}")
        EndIf

        Sleep(100)

        Local $nx = _ReadMemory($hProcess, $PosXAddress)
        Local $ny = _ReadMemory($hProcess, $PosYAddress)
        If $nx = $tx And $ny = $ty Then
            Return True
        EndIf
    Next
    Return False
EndFunc

; ------------------------------------------------------------------------------
; FIND CLOSEST LOCATION INDEX
; ------------------------------------------------------------------------------
Func FindClosestLocationIndex($currentX, $currentY, $aLocations)
    If Not IsArray($aLocations) Or UBound($aLocations, 0) = 0 Then
        ConsoleWrite("FindClosestLocationIndex => no valid array." & @CRLF)
        Return -1
    EndIf

    Local $minDist  = 999999
    Local $minIndex = -1
    For $i = 0 To UBound($aLocations) - 1
        Local $dx   = $currentX - $aLocations[$i][0]
        Local $dy   = $currentY - $aLocations[$i][1]
        Local $dist = $dx * $dx + $dy * $dy
        If $dist < $minDist Then
            $minDist  = $dist
            $minIndex = $i
        EndIf
    Next

    If $minIndex = -1 Then
        ConsoleWrite("FindClosestLocationIndex => no valid location found??" & @CRLF)
    Else
        ConsoleWrite("FindClosestLocationIndex => Found index: " & $minIndex & " Dist=" & $minDist & @CRLF)
    EndIf
    Return $minIndex
EndFunc

; ------------------------------------------------------------------------------
; 2D ARRAY HELPERS
; ------------------------------------------------------------------------------
Func _ArrayAdd2D_BFS(ByRef $arr, $xVal, $yVal, ByRef $count)
    Local $oldUB = UBound($arr, 1)
    If $count >= $oldUB Then
        ReDim $arr[$oldUB * 2][2]
    EndIf
    $arr[$count][0] = $xVal
    $arr[$count][1] = $yVal
EndFunc

Func _ArrayPrepend2D(ByRef $arr, $xVal, $yVal)
    Local $oldUB = UBound($arr, 1)
    ReDim $arr[$oldUB + 1][2]
    For $i = $oldUB - 1 To 0 Step -1
        $arr[$i + 1][0] = $arr[$i][0]
        $arr[$i + 1][1] = $arr[$i][1]
    Next
    $arr[0][0] = $xVal
    $arr[0][1] = $yVal
EndFunc

; ------------------------------------------------------------------------------
; GENERATE ±2 RANDOM OFFSETS & SHUFFLE
; ------------------------------------------------------------------------------
Func _GenerateRandomOffsets($x, $y, $range = 2)
    Local $aTemp[0][2]
    For $xx = $x - $range To $x + $range
        For $yy = $y - $range To $y + $range
            _ArrayAdd2D_Simple($aTemp, $xx, $yy)
        Next
    Next

    _Shuffle2D($aTemp)
    Return $aTemp
EndFunc

Func _ArrayAdd2D_Simple(ByRef $arr, $vx, $vy)
    Local $oldUB = UBound($arr, 1)
    ReDim $arr[$oldUB + 1][2]
    $arr[$oldUB][0] = $vx
    $arr[$oldUB][1] = $vy
EndFunc

Func _Shuffle2D(ByRef $arr)
    Local $count = UBound($arr, 1)
    For $i = 0 To $count - 1
        Local $j = Random($i, $count - 1, 1)
        If $j <> $i Then
            Local $tempX = $arr[$i][0]
            Local $tempY = $arr[$i][1]

            $arr[$i][0] = $arr[$j][0]
            $arr[$i][1] = $arr[$j][1]

            $arr[$j][0] = $tempX
            $arr[$j][1] = $tempY
        EndIf
    Next
EndFunc

Func TrashHeap()
    ; Remove if unused
EndFunc
