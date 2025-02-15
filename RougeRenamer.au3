#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Include\RougeRenamer.ico
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_Res_Description=Trainer for Project Rogue
#AutoIt3Wrapper_Res_Fileversion=3.0.0.17
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_ProductName=Rogue Reader
#AutoIt3Wrapper_Res_ProductVersion=3
#AutoIt3Wrapper_Res_CompanyName=Training Trainers.LLC
#AutoIt3Wrapper_Res_LegalCopyright=Use only for authorized security testing. Unauthorized use is illegal. No liability for misuse. ©TrainingTrainers.LLc 2024
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

Opt("MouseCoordMode", 2)

Global $version = FileGetVersion(@ScriptFullPath)

Global Const $locationFile = @ScriptDir & "\Locations.ini"
Global $currentLocations = 0
Global $maxLocations = 200

Global Const $sButtonConfigFile = @ScriptDir & "\ButtonConfig.ini"

ConsoleWrite("Script Version: " & $version & @CRLF)

; --- Load Config Settings ---
Global $HealHotkey = "" ; Default Heal Hotkey
Global $CureHotkey = "" ; Default Cure Hotkey
Global $TargetHotkey = "" ; Default Target Hotkey
Global $ExitHotkey = "" ; Default Exit Hotkey
Global $SaveLocationHotkey = "" ; Default Waypoint path location hotkey
Global $EraseLocationsHotkey = "" ; Default Location Clear
; Ensure Config File Exists and Load Config Settings
If Not FileExists($sButtonConfigFile) Then CreateButtonDefaultConfig()
LoadButtonConfig() ; Load or reload configuration settings

; --- Set Hotkeys from Config ---
HotKeySet($HealHotkey, "Hotkeyshit")
HotKeySet($CureHotkey, "CureKeyShit")
HotKeySet($TargetHotkey, "TargetKeyShit")
HotKeySet($ExitHotkey, "KilledWithFire")
HotKeySet($SaveLocationHotkey, "SaveLocation")
HotKeySet($EraseLocationsHotkey, "EraseLocations")

Global $Debug = False

; Define the game process and memory offsets
Global $ProcessName = "Project Rogue Client.exe"
Global $WindowName = "Project Rogue"
Global $TypeOffset = 0xBF0B98 ;x
Global $AttackModeOffset = 0xAACCC0 ;x
Global $PosXOffset = 0xBF3D28 ;Project Rogue Client.exe+BF3D28 #2 Project Rogue Client.exe+BF3D3C
Global $PosYOffset = 0xBF3D20 ;Project Rogue Client.exe+BF3D20 #2 Project Rogue Client.exe+BF3D34
Global $HPOffset = 0xAB5C30 ;x
Global $MaxHPOffset = 0xAB5C34 ;Project Rogue Client.exe+AB5C34
Global $ChattOpenOffset = 0x9B7A18 ;x
Global $SicknessOffset = 0xAB5E10

Global $currentTime = TimerInit()
Global $elapsedTime = TimerDiff($currentTime)

Global $LastHealTime = TimerInit()
Global $elapsedTimeSinceHeal = TimerDiff($LastHealTime)
Global $MovementTime = TimerInit()

Global $Running = True ;Does it loop;
Global $HealerStatus = 0
Global $CureStatus = 0
Global $TargetStatus = 0
Global $iPrevValue = 95
Global $MPrevValue = " "
Global $hProcess = 0 ; Our WinAPI handle to the process
Global $BaseAddress = 0 ; Base address of the module
Global $PosXOld = -1
Global $PosYOld = -1
Global $TypeAddress, $AttackModeAddress, $PosXAddress, $PosYAddress
Global $HPAddress, $MaxHPAddress, $ChattOpenAddress, $SicknessAddress
Global $Type, $Chat, $Sickness, $AttackMode
Global $SicknessDescription = GetSicknessDescription(0)

; This array is used in CureMe and TimeToHeal checks (it will cure on the sickness numbers listed only)
Global $sicknessArray = [1, 2, 65, 66, 67, 68, 69, 72, 73, 81, 97, 98, 99, 513, 514, 515, 577, 8193, 8194, 8195, 8257, 8258, 8705, 8706, 8707, 8708, 8709, 8712, 8713, 8721, 8737, 8769, 8770, 16385, 16386, 16449, 16450, 16451, 16452, 16897, 16898, 24577, 24578, 24579, 24581, 24582, 24583, 24585, 24609, 24641, 24642, 24643, 24645, 24646, 24647, 24649, 25089, 25090, 25091, 25093, 25094, 25095, 25097, 25121, 33283, 33284, 33285, 33286, 33287, 33288, 33289, 33291, 33293, 33294, 33295, 33793, 41985, 41986, 41987, 41988, 41989, 41990, 41991, 41993, 41995]

Global $TargetDelay = 400, $HealDelay = 1700
Global $aMousePos = MouseGetPos()

; Create the GUI
Global $Gui = GUICreate("RougeRenamer " & "StandaloneVersion", 400, 400, 15, 15)
Global $TypeLabel = GUICtrlCreateLabel("Type: N/A", 20, 30, 250, 20)
Global $AttackModeLabel = GUICtrlCreateLabel("Attack Mode: N/A", 20, 60, 250, 20)
Global $PosXLabel = GUICtrlCreateLabel("Pos X: N/A", 20, 90, 250, 20)
Global $PosYLabel = GUICtrlCreateLabel("Pos Y: N/A", 20, 120, 250, 20)
Global $HPLabel = GUICtrlCreateLabel("HP: N/A", 20, 150, 250, 20)
Global $ChatLabel = GUICtrlCreateLabel("Chat: N/A", 120, 150, 250, 20)
Global $HP2Label = GUICtrlCreateLabel("RealHp: N/A", 20, 180, 250, 20)
Global $SicknessLabel = GUICtrlCreateLabel("Sickness: N/A", 120, 180, 250, 20)

Global $MaxHPLabel = GUICtrlCreateLabel("MaxHP: N/A", 20, 210, 250, 20)


Global $TargetLabel = GUICtrlCreateLabel("Target: Off", 120, 210, 250, 20)
Global $HealerLabel = GUICtrlCreateLabel("Healer: Off", 20, 240, 250, 20)
Global $CureLabel = GUICtrlCreateLabel("Cure: Off", 120, 240, 250, 20)
Global $HotkeyLabel = GUICtrlCreateLabel("Set hotkeys in the config file", 20, 270, 350, 20)
Global $KillButton = GUICtrlCreateButton("Kill Rogue", 20, 300, 100, 30)
Global $ExitButton = GUICtrlCreateButton("Exit", 150, 300, 100, 30)
Global $healSlider = GUICtrlCreateSlider(20, 350, 200, 20)
Global $healsliderlimit = GUICtrlSetLimit($healSlider, 95, 45) ; Set range from 45 to 95
Global $setsliderdata = GUICtrlSetData($healSlider, 75) ; Set initial position to 45
Global $healLabel = GUICtrlCreateLabel("Heal at: " & $healSlider&"%", 230, 350, 100, 20)
Global $MovmentSlider = GUICtrlCreateSlider(20, 370, 180, 20)
Global $Movmentsliderlimit = GUICtrlSetLimit($MovmentSlider, 750, 50)
Global $setsliderdata = GUICtrlSetData($MovmentSlider, 150)
Global $MoveLabel = GUICtrlCreateLabel("Heal After  "&$MovmentSlider, 185, 370, 100, 20)
Global $MoveLabell = GUICtrlCreateLabel("ms of no movment.", 280, 370, 100, 20)


GUISetState(@SW_SHOW)
; ------------------------------------------------------------------------------
; MAIN LOOP
; ------------------------------------------------------------------------------
While 1
    Global $ProcessID = ProcessExists($ProcessName)
    If $ProcessID Then
        ConnectToBaseAddress()
        If $BaseAddress = 0 Or $hProcess = 0 Then
            Sleep(300)
        Else
            ; Check if the window exists, and rename it
            If WinExists($WindowName) Then
                WinSetTitle($WindowName, "", "Project Rogue1")
                $WindowName = "Project Rogue1"
            EndIf

            ChangeAddressToBase()
            While $Running And ProcessExists($ProcessID) ; Keep running while process exists
                Local $elapsedTime = TimerDiff($currentTime)
                Local $msg = GUIGetMsg()

                If $msg = $ExitButton Or $msg = $GUI_EVENT_CLOSE Then
                    _WinAPI_CloseHandle($hProcess)
                    GUIDelete($Gui)
                    ConsoleWrite("[Debug] Trainer closed, 3" & @CRLF)
                    Exit
                EndIf



                If $msg = $KillButton Then
                    ProcessClose($ProcessID)
                    ExitLoop
                EndIf



                If $Chat = 0 Then ;make sure chat is closed to send heals/target
                    If $CureStatus = 1 Then
                        CureMe()
                    EndIf
                    If $TargetStatus = 1 Then
                        AttackModeReader()
                    EndIf
                    If $HealerStatus = 1 Then
                        TimeToHeal()
                    EndIf
                EndIf
                GUIReadMemory()
                Sleep(100)
                ; Check if game is still running, if not, exit the inner loop to reconnect
                If Not ProcessExists($ProcessID) Then
                    ConsoleWrite("[Info] Game closed, waiting to reconnect..." & @CRLF)
                    ExitLoop
                EndIf
            WEnd
            Local $msg = GUIGetMsg()
            If $msg = $ExitButton Or $msg = the GUI_EVENT_CLOSE Then
                _WinAPI_CloseHandle($hProcess)
                GUIDelete($Gui)
                ConsoleWrite("[Debug] Trainer closed, 1" & @CRLF)
                Exit
            EndIf

            If $msg = $KillButton Then
                ProcessClose($ProcessID)
                ExitLoop
            EndIf
        EndIf
    Else
        ConsoleWrite("[Info] Game not found, waiting..." & @CRLF)
        ; Keep checking every 2 seconds until game is reopened
        While Not ProcessExists($ProcessName)
            Local $msg = GUIGetMsg()
            Sleep(50)
            If $msg = $ExitButton Or $msg = the GUI_EVENT_CLOSE Then
                _WinAPI_CloseHandle($hProcess)
                GUIDelete($Gui)
                ConsoleWrite("[Debug] Trainer closed, 2" & @CRLF)
                Exit
            EndIf
            If $msg = the KillButton Then
                ProcessClose($ProcessID)
                ExitLoop
            EndIf


            $MValue = GUICtrlRead($MovmentSlider)
            $iValue = GUICtrlRead($healSlider)


            ; Update label only if the value has changed
            If $iValue <> $iPrevValue Then ;healing percent Lable in Gui Updater when game is not loaded;
                GUICtrlSetData($healLabel, "Heal at: " & $iValue & "%")
                $iPrevValue = $iValue ; Store new value for comparison
            EndIf
            If $MValue <> $MPrevValue Then ;Movement timer Lable in Gui Updater when game is not loaded;
                GUICtrlSetData($MoveLabel, "Heal After  "& $MValue)
                $MPrevValue = $MValue ; Store new value for comparison
            EndIf
        WEnd
        ConsoleWrite("[Info] Game detected, reconnecting..." & @CRLF)
    EndIf


;Adding Comments to change the Checksum;
;Adding Comments to change the Checksum;
;Adding Comments to change the Checksum;
;Adding Comments to change the Checksum;
;Adding Comments to change the Checksum;
;Adding Comments to change the Checksum;
;Adding Comments to change the Checksum;
;Adding Comments to change the Checksum;
;Adding Comments to change the Checksum;
;Adding Comments to change the Checksum;
;Adding Comments to change the Checksum;
;Adding Comments to change the Checksum;
;Adding Comments to change the Checksum;
;Adding Comments to change the Checksum;
;Adding Comments to change the Checksum;
;Adding Comments to change the Checksum;
;Adding Comments to change the Checksum;

WEnd
; Cleanup


GUIDelete($Gui)
_WinAPI_CloseHandle($hProcess)
ConsoleWrite("[Debug] Trainer closed, 0" & @CRLF)
Exit

; ------------------------------------------------------------------------------
; LOAD CONFIG
; ------------------------------------------------------------------------------
Func LoadButtonConfig()
    Local $aKeys[7][2] = [["HealHotkey", "{f7}"], ["CureHotkey", "{f8}"], ["TargetHotkey", "{f9}"], ["ExitHotkey", "{f10}"], ["SaveLocationHotkey", "{f11}"], ["EraseLocationsHotkey", "{f12}"], ["PlayLocationsHotkey", "{*}"]]
    For $i = 0 To UBound($aKeys) - 1
        ; Read each key from the INI file, default to predefined hotkeys if not found
        Local $sKey = IniRead($sButtonConfigFile, "Hotkeys", $aKeys[$i][0], $aKeys[$i][1])
        If $sKey = "" Then
            ; If INI read fails or returns an empty string, log the error and use the default
            ConsoleWrite("Failed to read " & $aKeys[$i][0] & " from INI. Using default: " & $aKeys[$i][1] & @CRLF)
            $sKey = $aKeys[$i][1]
        EndIf

        ; Set the hotkey to the corresponding function based on what is read or defaulted
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
            Case "PlayLocationsHotkey"
                ; Ensure you have a corresponding function for this hotkey
                HotKeySet($sKey, "PlayLocationsFunc") ; Make sure the function 'PlayLocationsFunc' exists
        EndSwitch

        ConsoleWrite("Hotkey for " & $aKeys[$i][0] & " set to " & $sKey & @CRLF)
    Next
EndFunc

Func CreateButtonDefaultConfig()
    ; Declare the array with dimensions
    Local $aKeys[7][2]

    ; Initialize the array with hotkeys and default values
    $aKeys[0][0] = "HealHotkey"
    $aKeys[0][1] = "{`}"


    $aKeys[1][0] = "CureHotkey"
    $aKeys[1][1] = "{-}"


    $aKeys[2][0] = "TargetHotkey"
    $aKeys[2][1] = "{]}"


    $aKeys[3][0] = "ExitHotkey"
    $aKeys[3][1] = "{/}"


    $aKeys[4][0] = "SaveLocationHotkey"
    $aKeys[4][1] = "{,}"

    $aKeys[5][0] = "EraseLocationsHotkey"
    $aKeys[5][1] = "{.}"


    $aKeys[6][0] = "PlayLocationsHotkey"
    $aKeys[6][1] = "{*}"


    For $i = 0 To UBound($aKeys) - 1
        IniWrite($sButtonConfigFile, "Hotkeys", $aKeys[$i][0], $aKeys[$i][1])
    Next

    ConsoleWrite("[Info] Default ButtonConfig.ini created with hotkeys." & @CRLF)
EndFunc
; ------------------------------------------------------------------------------
; READ AND UPDATE GUI FROM MEMORY
; ------------------------------------------------------------------------------
Func GUIReadMemory()

    If $hProcess = 0 Then Return
    ; Read Type
    $PrevType = " "
    $Type = _ReadMemory($hProcess, $TypeAddress)
    If $Type <> $PrevType Then
        If $Type = 0 Then
            GUICtrlSetData($TypeLabel, "Type: Player")
            $PrevType = $Type
        ElseIf $Type = 1 Then
            GUICtrlSetData($TypeLabel, "Type: Monster")
            $PrevType = $Type
        ElseIf $Type = 2 Then
            GUICtrlSetData($TypeLabel, "Type: NPC")
            $PrevType = $Type
        ElseIf $Type = 65535 Then
            GUICtrlSetData($TypeLabel, "Type: No Target")
            $PrevType = $Type
        Else
            GUICtrlSetData($TypeLabel, "Type: Unknown (" & $Type & ")")
            $PrevType = $Type
        EndIf
    EndIf
    ; Attack Mode

    $AttackMode = _ReadMemory($hProcess, $AttackModeAddress)
    If $AttackMode = 0 Then
        GUICtrlSetData($AttackModeLabel, "Attack Mode: Safe")
    ElseIf $AttackMode = 1 Then
        GUICtrlSetData($AttackModeLabel, "Attack Mode: Attack")
    Else
        GUICtrlSetData($AttackModeLabel, "Attack Mode: No Target")
    EndIf
    $iValue = GUICtrlRead($healSlider)
    ; Update label only if the value has changed
    If $iValue <> $iPrevValue Then
        GUICtrlSetData($healLabel, "Heal at: " & $iValue & "%")
        $iPrevValue = $iValue ; Store new value for comparison
    EndIf
    $MValue = GUICtrlRead($MovmentSlider)
    If $MValue <> $MPrevValue Then ;Movement timer Lable in Gui Updater when game is loaded;
        GUICtrlSetData($MoveLabel, "Heal After  "& $MValue)
        $MPrevValue = $MValue ; Store new value for comparison
    EndIf
    ; Position
    Local $PosXOld = " "
    Local $PosYOld = " "
    Local $PosX = _ReadMemory($hProcess, $PosXAddress)
    Local $PosY = _ReadMemory($hProcess, $PosYAddress)
    If $PosX <> $PosXOld Then
        GUICtrlSetData($PosXLabel, "Pos X: " & $PosX)
        $PosXOld = $PosX
    EndIf
    If $PosY <> $PosYOld Then
        GUICtrlSetData($PosYLabel, "Pos Y: " & $PosY)
        $PosYOld = $PosY
    EndIf
    ; HP
    Local $HP = _ReadMemory($hProcess, $HPAddress)
    GUICtrlSetData($HPLabel, "HP: " & $HP)
    GUICtrlSetData($HP2Label, "RealHp: " & $HP / 65536)
    ; MaxHP
    Local $MaxHP = _ReadMemory($hProcess, $MaxHPAddress)
    GUICtrlSetData($MaxHPLabel, "MaxHP: " & $MaxHP)
    ; Chat
    Local $ChatVal = _ReadMemory($hProcess, $ChattOpenAddress)
    $Chat = $ChatVal
    GUICtrlSetData($ChatLabel, "Chat: " & $ChatVal)
    ; Sickness
    Local $SickVal = _ReadMemory($hProcess, $SicknessAddress)
    $Sickness = $SickVal
    $SicknessDescription = GetSicknessDescription($SickVal)
    GUICtrlSetData($SicknessLabel, "Sickness: " & $SicknessDescription)
    Sleep(50)
EndFunc   ;==>GUIReadMemory

; ------------------------------------------------------------------------------
;                                  CURE FUNCTION
; ------------------------------------------------------------------------------
Func CureMe()
    If $Chat <> 0 Then
        Sleep(50)
        Return ; Optionally add a return message if needed
    EndIf
    $Sickness = _ReadMemory($hProcess, $SicknessAddress)
    $Healwait = GUICtrlRead($MovmentSlider)  ; Read movement slider value for delay
    $HP = _ReadMemory($hProcess, $HPAddress)
    $RealHP = $HP / 65536
    $MaxHP = _ReadMemory($hProcess, $MaxHPAddress)
    $ChatVal = _ReadMemory($hProcess, $ChattOpenAddress)
    $SickVal = _ReadMemory($hProcess, $SicknessAddress)
    $HealThreshold = GUICtrlRead($healSlider) / 100


    If _ArraySearch($sicknessArray, $Sickness) <> -1 Then
    $CurrentX = Number(StringRegExpReplace(GUICtrlRead($PosXLabel), "[^\d]", ""))
    $CurrentY = Number(StringRegExpReplace(GUICtrlRead($PosYLabel), "[^\d]", ""))
    Static $LastX = $CurrentX
    Static $LastY = $CurrentY


    $elapsedTimeSinceHeal = TimerDiff($LastHealTime)  ; Update the elapsed time since last heal

    ConsoleWrite("Healing check initiated..." & @CRLF)
    ConsoleWrite("Current HP: " & $RealHP & " / " & $MaxHP & " Threshold: " & $HealThreshold & @CRLF)
    ConsoleWrite("Heal Delay: " & $HealDelay & " ms, Heal wait (no movement): " & $Healwait & " ms" & @CRLF)
    ConsoleWrite("Current Position: X=" & $CurrentX & " Y=" & $CurrentY & " Last Position: X=" & $LastX & " Y=" & $LastY & @CRLF)
    ConsoleWrite("Time since last heal: " & $elapsedTimeSinceHeal & " ms" & @CRLF)

    If $CurrentX <> $LastX Or $CurrentY <> $LastY Then
        ConsoleWrite("Movement detected, resetting movement timer." & @CRLF)
        $LastX = $CurrentX
        $LastY = $CurrentY
        $MovementTime = TimerInit()  ; Reset timer if position changed
    EndIf

    If $elapsedTimeSinceHeal >= $HealDelay Then

            If TimerDiff($MovementTime) > $Healwait Then
                ControlSend("Project Rogue1", "", "", "{3}")
                ConsoleWrite("Healing triggered: HP below threshold and no movement for " & $Healwait & " ms." & @CRLF)
                $LastHealTime = TimerInit()  ; Reset main timer after healing
            Else
                ConsoleWrite("No healing: Waiting for no movement duration to pass. " & (TimerDiff($MovementTime)) & " ms passed." & @CRLF)
            EndIf

    Else
        ConsoleWrite("Healing blocked: Chat open or under sickness effect, or insufficient time elapsed since last heal." & @CRLF)
    EndIf
    EndIf
EndFunc   ;==>CureMe

; ------------------------------------------------------------------------------
;                                   HEALER
; ------------------------------------------------------------------------------
; Update function to read slider value
; Initialize this at the start of your script

Func TimeToHeal()
    $Healwait = GUICtrlRead($MovmentSlider)  ; Read movement slider value for delay
    $HP = _ReadMemory($hProcess, $HPAddress)
    $RealHP = $HP / 65536
    $MaxHP = _ReadMemory($hProcess, $MaxHPAddress)
    $ChatVal = _ReadMemory($hProcess, $ChattOpenAddress)
    $SickVal = _ReadMemory($hProcess, the SicknessAddress)
    $HealThreshold = GUICtrlRead($healSlider) / 100

    $CurrentX = Number(StringRegExpReplace(GUICtrlRead($PosXLabel), "[^\d]", ""))
    $CurrentY = Number(StringRegExpReplace(GUICtrlRead($PosYLabel), "[^\d]", ""))
    Static $LastX = $CurrentX
    Static $LastY = $CurrentY

    $elapsedTimeSinceHeal = TimerDiff($LastHealTime)  ; Update the elapsed time since last heal

    ConsoleWrite("Healing check initiated..." & @CRLF)
    ConsoleWrite("Current HP: " & $RealHP & " / " & $MaxHP & " Threshold: " & $HealThreshold & @CRLF)
    ConsoleWrite("Heal Delay: " & $HealDelay & " ms, Heal wait (no movement): " & $Healwait & " ms" & @CRLF)
    ConsoleWrite("Current Position: X=" & $CurrentX & " Y=" & $CurrentY & " Last Position: X=" & $LastX & " Y=" & $LastY & @CRLF)
    ConsoleWrite("Time since last heal: " & $elapsedTimeSinceHeal & " ms" & @CRLF)

    If $CurrentX <> $LastX Or $CurrentY <> $LastY Then
        ConsoleWrite("Movement detected, resetting movement timer." & @CRLF)
        $LastX = $CurrentX
        $LastY = $CurrentY
        $MovementTime = TimerInit()  ; Reset timer if position changed
    EndIf

    If $ChatVal = 0 And _ArraySearch($sicknessArray, $Sickness) = -1 And $elapsedTimeSinceHeal >= $HealDelay Then
    If $RealHP < ($MaxHP * $HealThreshold) Then
        If TimerDiff($MovementTime) > $Healwait Then
            ControlSend("Project Rogue1", "", "", "{2}")
            ConsoleWrite("Healing triggered: HP below threshold and no movement for " & $Healwait & " ms." & @CRLF)
            $LastHealTime = TimerInit()  ; Reset main timer after healing
        Else
            ConsoleWrite("No healing: Waiting for no movement duration to pass. " & (TimerDiff($MovementTime)) & " ms passed." & @CRLF)
        EndIf
    Else
        ConsoleWrite("No healing needed: HP above threshold." & @CRLF)
    EndIf
Else
    ConsoleWrite("Healing blocked: Chat open or under sickness effect, or insufficient time elapsed since last heal." & @CRLF)
EndIf
EndFunc   ;==>TimeToHeal

; ------------------------------------------------------------------------------
;                                  TARGETING
; ------------------------------------------------------------------------------
Func AttackModeReader()
    $ChatVal = _ReadMemory($hProcess, $ChattOpenAddress)
    $Chat = $ChatVal
    $AttackMode = _ReadMemory($hProcess, $AttackModeAddress)
    If $AttackMode = 0 Then
        GUICtrlSetData($AttackModeLabel, "Attack Mode: Safe")
    ElseIf $AttackMode = 1 Then
        GUICtrlSetData($AttackModeLabel, "Attack Mode: Attack")
        If $Type = 0 Then
            ConsoleWrite("Type: Player" & @CRLF)
        ElseIf $Type = 65535 Then
            Local $elapsedTime = TimerDiff($currentTime)
            If $Chat = 0 Then
                If $elapsedTime >= $TargetDelay Then
                    If $chat = 0 Then
                    ControlSend("Project Rogue1", "", "", "{TAB}") ;target next mob
                    $currentTime = TimerInit()
                    EndIf

                EndIf
            Else
                If $elapsedTime >= $TargetDelay Then
                    ConsoleWrite("[Debug] chat open" & @CRLF) ;chat is open it shouldnt do anything
                    $currentTime = TimerInit()
                EndIf
            EndIf
        ElseIf $Type = 1 Then
            ; "Monster targeted"

        ElseIf $Type = 2 Then


            ; "Type: NPC"


        Else
            ConsoleWrite("Type: " & $Type & @CRLF)



        EndIf
    Else
        GUICtrlSetData($AttackModeLabel, "Attack Mode: No Target")
    EndIf
EndFunc   ;==>AttackModeReader

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
EndFunc   ;==>ConnectToBaseAddress

Func ChangeAddressToBase()
    $TypeAddress = $BaseAddress + $TypeOffset
    $AttackModeAddress = $BaseAddress + $AttackModeOffset
    $PosXAddress = $BaseAddress + $PosXOffset
    $PosYAddress = $BaseAddress + $PosYOffset
    $HPAddress = $BaseAddress + $HPOffset
    $MaxHPAddress = $BaseAddress + $MaxHPOffset
    $ChattOpenAddress = $BaseAddress + $ChattOpenOffset
    $SicknessAddress = $BaseAddress + $SicknessOffset
EndFunc   ;==>ChangeAddressToBase

Func _GetModuleBase_EnumModules($hProcess)
    Local $hPsapi = DllOpen("psapi.dll")
    If $hPsapi = 0 Then Return 0
    Local $tModules = DllStructCreate("ptr[1024]")
    Local $tBytesNeeded = DllStructCreate("dword")
    Local $aCall = DllCall("psapi.dll", "bool", "EnumProcessModules", _
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
EndFunc   ;==>_GetModuleBase_EnumModules

Func _ReadMemory($hProcess, $pAddress)
    If $hProcess = 0 Or $pAddress = 0 Then Return 0
    Local $tBuffer = DllStructCreate("dword")
    Local $aRead = DllCall("kernel32.dll", "bool", "ReadProcessMemory", _
            "handle", $hProcess, _
            "ptr", $pAddress, _
            "ptr", DllStructGetPtr($tBuffer), _
            "dword", DllStructGetSize($tBuffer), _
            "ptr", 0)
    If @error Or Not $aRead[0] Then
        Return 0
    EndIf
    Return DllStructGetData($tBuffer, 1)
EndFunc   ;==>_ReadMemory

Func Hotkeyshit()
    $HealerStatus = Not $HealerStatus
    GUICtrlSetData($HealerLabel, "Healer: " & ($HealerStatus ? "On" : "Off"))
    Sleep(300)
EndFunc   ;==>Hotkeyshit

Func CureKeyShit()
    $CureStatus = Not $CureStatus
    GUICtrlSetData($CureLabel, "Cure: " & ($CureStatus ? "On" : "Off"))
    Sleep(300)
EndFunc   ;==>CureKeyShit

Func TargetKeyShit()

    $TargetStatus = Not $TargetStatus
    GUICtrlSetData($TargetLabel, "Target: " & ($TargetStatus ? "On" : "Off"))
    Sleep(300)

EndFunc   ;==>TargetKeyShit

Func KilledWithFire()

    If $Debug Then ConsoleWrite("Killed with fire" & @CRLF)
    Exit
EndFunc   ;==>KilledWithFire

Func GetSicknessDescription($Sick)
    Global $SicknessDescription = "Unknown"
    Switch $Sick
        Case 1
            $SicknessDescription = "Poison1"& $Sickness
        Case 2
            $SicknessDescription = "Disease1"& $Sickness
        Case 4
            $SicknessDescription = "Poison4"& $Sickness
        Case 8
            $SicknessDescription = "Disease5"& $Sickness
        Case 16
            $SicknessDescription = "New Affliction 16"& $Sickness
        Case 32
            $SicknessDescription = "New Affliction 32"& $Sickness
        Case 64
            $SicknessDescription = "Vampirism"& $Sickness
        Case 65
            $SicknessDescription = "Vampirism + Poison1"& $Sickness
        Case 66
            $SicknessDescription = "Vampirism + Disease1"& $Sickness
        Case 67
            $SicknessDescription = "Vampirism + Poison1 + Disease1"
        Case 68
            $SicknessDescription = "Vampirism + Poison4"& $Sickness
        Case 69
            $SicknessDescription = "Vampirism + Poison1 + Poison4"& $Sickness
        Case 72
            $SicknessDescription = "Vampirism + Disease5"& $Sickness
        Case 73
            $SicknessDescription = "Vampirism + Poison1 + Disease5"& $Sickness
        Case 80
            $SicknessDescription = "Vampirism + New Affliction 16"& $Sickness
        Case 81
            $SicknessDescription = "Vampirism + Poison1 + New Affliction 16"& $Sickness
        Case 96
            $SicknessDescription = "Vampirism + New Affliction 32"& $Sickness
        Case 97
            $SicknessDescription = "Vampirism + Poison1 + New Affliction 32"& $Sickness
        Case 98
            $SicknessDescription = "Poison3"& $Sickness
        Case 99
            $SicknessDescription = "Disease23"& $Sickness
        Case 320
            $SicknessDescription = "Vampirism"& $Sickness
        Case 512
            $SicknessDescription = "Swiftness"& $Sickness
        Case 576
            $SicknessDescription = "Swiftness + Vampirism"& $Sickness
        Case 577
            $SicknessDescription = "Swiftness + Vampirism + Poison1"& $Sickness
        Case 8192
            $SicknessDescription = "BloodLust"& $Sickness
        Case 8193
            $SicknessDescription = "BloodLust + Poison1"& $Sickness
        Case 8194
            $SicknessDescription = "BloodLust + Disease1"& $Sickness
        Case 8195
            $SicknessDescription = "BloodLust + Poison1 + Disease1"& $Sickness
        Case 8256
            $SicknessDescription = "BloodLust + Vampirism"& $Sickness
        Case 8257
            $SicknessDescription = "BloodLust + Vampirism + Poison1"& $Sickness
        Case 8258
            $SicknessDescription = "BloodLust + Vampirism + Poison1 + Disease1"& $Sickness
        Case 8704
            $SicknessDescription = "BloodLust + Swiftness"& $Sickness
        Case 8705
            $SicknessDescription = "BloodLust + Swiftness + Poison1"& $Sickness
        Case 8706
            $SicknessDescription = "BloodLust + Swiftness + Disease1"& $Sickness
        Case 8707
            $SicknessDescription = "BloodLust + Swiftness + Poison1 + Disease1"& $Sickness
        Case 8708
            $SicknessDescription = "BloodLust + Swiftness + Poison4"& $Sickness
        Case 8709
            $SicknessDescription = "BloodLust + Swiftness + Poison1 + Poison4"& $Sickness
        Case 8712
            $SicknessDescription = "BloodLust + Swiftness + Disease5"& $Sickness
        Case 8713
            $SicknessDescription = "BloodLust + Swiftness + Poison1 + Disease5"& $Sickness
        Case 8720
            $SicknessDescription = "BloodLust + Swiftness + New Affliction 16"& $Sickness
        Case 8721
            $SicknessDescription = "BloodLust + Swiftness + Poison1 + New Affliction 16"& $Sickness
        Case 8736
            $SicknessDescription = "BloodLust + Swiftness + New Affliction 32"& $Sickness
        Case 8737
            $SicknessDescription = "BloodLust + Swiftness + Poison1 + New Affliction 32"& $Sickness
        Case 8768
            $SicknessDescription = "BloodLust + Swiftness + Vampirism"& $Sickness
        Case 8769
            $SicknessDescription = "BloodLust + Swiftness + Vampirism + Poison1"& $Sickness
        Case 8770
            $SicknessDescription = "BloodLust + Swiftness + Vampirism + Disease1"& $Sickness
        Case 16384
            $SicknessDescription = "Exhausted"& $Sickness
        Case 16385
            $SicknessDescription = "Exhausted + Poison1"& $Sickness
        Case 16386
            $SicknessDescription = "Exhausted + Disease1"& $Sickness
        Case 16448
            $SicknessDescription = "Exhausted + Vampirism"& $Sickness
        Case 16449
            $SicknessDescription = "Exhausted + Vampirism + Poison1"& $Sickness
        Case 16450
            $SicknessDescription = "Exhausted + Disease1"& $Sickness
        Case 16451
            $SicknessDescription = "Exhausted + Poison1 + Disease1"& $Sickness
        Case 16452
            $SicknessDescription = "Exhausted + Poison4 + Disease1 + Vampirism"& $Sickness
        Case 16896
            $SicknessDescription = "Swiftness + Exhausted"& $Sickness
        Case 16897
            $SicknessDescription = "Swiftness + Exhausted + Poison1"& $Sickness
        Case 16898
            $SicknessDescription = "Swiftness + Exhausted + Disease1"& $Sickness
        Case 16929
            $SicknessDescription = "Swiftness + Exhausted + Vampirism + Poison1"& $Sickness
        Case 24576
            $SicknessDescription = "BloodLust + Exhausted"& $Sickness
        Case 24577
            $SicknessDescription = "BloodLust + Exhausted + Poison1"& $Sickness
        Case 24578
            $SicknessDescription = "BloodLust + Exhausted + Disease1"& $Sickness
        Case 24579
            $SicknessDescription = "BloodLust + Exhausted + Poison1 + Disease1"& $Sickness
        Case 24580
            $SicknessDescription = "BloodLust + Exhausted + Poison4"& $Sickness
        Case 24581
            $SicknessDescription = "BloodLust + Exhausted + Poison1 + Poison4"& $Sickness
        Case 24582
            $SicknessDescription = "BloodLust + Exhausted + Disease5"& $Sickness
        Case 24583
            $SicknessDescription = "BloodLust + Exhausted + Poison1 + Disease5"& $Sickness
        Case 24584
            $SicknessDescription = "BloodLust + Exhausted + New Affliction 16"& $Sickness
        Case 24585
            $SicknessDescription = "BloodLust + Exhausted + Poison1 + New Affliction 16"& $Sickness
        Case 24608
            $SicknessDescription = "BloodLust + Exhausted + New Affliction 32"& $Sickness
        Case 24609
            $SicknessDescription = "BloodLust + Exhausted + Poison1 + New Affliction 32"& $Sickness
        Case 24640
            $SicknessDescription = "BloodLust + Exhausted + Vampirism"& $Sickness
        Case 24641
            $SicknessDescription = "BloodLust + Exhausted + Vampirism + Poison1"& $Sickness
        Case 24642
            $SicknessDescription = "BloodLust + Exhausted + Vampirism + Disease1"& $Sickness
        Case 24643
            $SicknessDescription = "BloodLust + Exhausted + Vampirism + Poison1 + Disease1"& $Sickness
        Case 24644
            $SicknessDescription = "BloodLust + Exhausted + Vampirism + Poison4"& $Sickness
        Case 24645
            $SicknessDescription = "BloodLust + Exhausted + Vampirism + Poison1 + Poison4"& $Sickness
        Case 24646
            $SicknessDescription = "BloodLust + Exhausted + Vampirism + Disease5"& $Sickness
        Case 24647
            $SicknessDescription = "BloodLust + Exhausted + Vampirism + Poison1 + Disease5"& $Sickness
        Case 24648
            $SicknessDescription = "BloodLust + Exhausted + Vampirism + New Affliction 16"& $Sickness
        Case 24649
            $SicknessDescription = "BloodLust + Exhausted + Vampirism + Poison1 + New Affliction 16"& $Sickness
        Case 24672
            $SicknessDescription = "BloodLust + Exhausted + Vampirism + New Affliction 32"& $Sickness
        Case 24673
            $SicknessDescription = "BloodLust + Exhausted + Vampirism + Poison1 + New Affliction 32"& $Sickness
        Case 25088
            $SicknessDescription = "BloodLust + Exhausted + Swiftness"& $Sickness
        Case 25089
            $SicknessDescription = "BloodLust + Exhausted + Swiftness + Poison1"& $Sickness
        Case 25090
            $SicknessDescription = "BloodLust + Exhausted + Swiftness + Disease1"& $Sickness
        Case 25091
            $SicknessDescription = "BloodLust + Exhausted + Swiftness + Poison1 + Disease1"& $Sickness
        Case 25092
            $SicknessDescription = "BloodLust + Exhausted + Swiftness + Poison4"& $Sickness
        Case 25093
            $SicknessDescription = "BloodLust + Exhausted + Swiftness + Poison1 + Poison4"& $Sickness
        Case 25094
            $SicknessDescription = "BloodLust + Exhausted + Swiftness + Disease5"& $Sickness
        Case 25095
            $SicknessDescription = "BloodLust + Exhausted + Swiftness + Poison1 + Disease5"& $Sickness
        Case 25096
            $SicknessDescription = "BloodLust + Exhausted + Swiftness + New Affliction 16"& $Sickness
        Case 25097
            $SicknessDescription = "BloodLust + Exhausted + Swiftness + Poison1 + New Affliction 16"& $Sickness
        Case 25120
            $SicknessDescription = "BloodLust + Exhausted + Swiftness + New Affliction 32"& $Sickness
        Case 25121
            $SicknessDescription = "BloodLust + Exhausted + Swiftness + Poison1 + New Affliction 32"& $Sickness
        Case 33280
            $SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism"& $Sickness
        Case 33283
            $SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Poison1"& $Sickness
        Case 33284
            $SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Disease1"& $Sickness
        Case 33285
            $SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Poison1 + Disease1"& $Sickness
        Case 33286
            $SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Poison4"& $Sickness
        Case 33287
            $SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Poison1 + Poison4"& $Sickness
        Case 33288
            $SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Disease5"& $Sickness
        Case 33289
            $SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Poison1 + Disease5"& $Sickness
        Case 33290
            $SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + New Affliction 16"& $Sickness
        Case 33291
            $SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Poison1 + New Affliction 16"& $Sickness
        Case 33292
            $SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + New Affliction 32"& $Sickness
        Case 33293
            $SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Poison1 + New Affliction 32"& $Sickness
        Case 33294
            $SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Poison3"& $Sickness
        Case 33295
            $SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Disease23"& $Sickness
        Case 33792
            $SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Swiftness"& $Sickness
        Case 33793
            $SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Swiftness + Poison1"& $Sickness
        Case 41984
            $SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Desperation"& $Sickness
        Case 41985
            $SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Desperation + Poison1"& $Sickness
        Case 41986
            $SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Desperation + Disease1"& $Sickness
        Case 41987
            $SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Desperation + Poison1 + Disease1"& $Sickness
        Case 41988
            $SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Desperation + Poison4"& $Sickness
        Case 41989
            $SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Desperation + Poison1 + Poison4"& $Sickness
        Case 41990
            $SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Desperation + Disease5"& $Sickness
        Case 41991
            $SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Desperation + Poison1 + Disease5"& $Sickness
        Case 41992
            $SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Desperation + New Affliction 16"& $Sickness
        Case 41993
            $SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Desperation + Poison1 + New Affliction 16"& $Sickness
        Case 41994
            $SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Desperation + New Affliction 32"& $Sickness
        Case 41995
            $SicknessDescription = "Swiftness + Exhausted + Desperation + Vampirism + Desperation + Poison1 + New Affliction 32"& $Sickness
        Case Else
            $SicknessDescription = $Sickness
    EndSwitch
    Return $SicknessDescription
EndFunc   ;==>GetSicknessDescription




Func SaveLocation()
    Local $x = _ReadMemory($hProcess, $PosXOffset)
    Local $y = _ReadMemory($hProcess, $PosYOffset)
    Local $pos = [$x, $y]

    ConsoleWrite("Current X: " & $x & " Y: " & $y & @CRLF)

    ; Check if the positions have changed since the last check
    If $x == $PosXOld And $y == $PosYOld Then
        ConsoleWrite("Position unchanged. No action taken." & @CRLF)
        Return  ; Exit the function if no change in position
    EndIf

    ; Update old positions to the current ones
    $PosXOld = $x
    $PosYOld = $y

    ; Increment location count
    $currentLocations += 1
    ConsoleWrite("Saving new position at index " & $currentLocations & @CRLF)

    ; Save new position
    _FileWriteFromArray($locationFile, $pos, $currentLocations, False)

    ; Check for maximum capacity
    If $currentLocations >= $maxLocations Then
        ConsoleWrite("Maximum locations reached. Emitting beep and resetting counter." & @CRLF)
        Beep(500, 100)  ; Quieter system beep for 100 milliseconds
        $currentLocations = 0  ; Optionally reset or handle overflow differently
    EndIf
EndFunc
Func EraseLocations()

    ;FileDelete($sConfigFile)
    ;MsgBox(64, "Success", "All locations erased.")

EndFunc

Func TrashHeap()
    ; Remove Function;
EndFunc   ;==>TrashHeap
