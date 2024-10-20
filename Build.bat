@echo off
:: Navigate to the script directory
cd C:\Users\gooro\OneDrive\Desktop\RogueReader

:: Check if pyinstaller exists in the user installation directory
if exist "C:\Users\gooro\AppData\Roaming\Python\Python313\Scripts\pyinstaller.exe" (
    echo PyInstaller found. Proceeding with conversion...
) else (
    echo PyInstaller not found. Installing it...
    python -m pip install pyinstaller
)

:: Run PyInstaller with the specified icon, in one file, without console window
"C:\Users\gooro\AppData\Roaming\Python\Python313\Scripts\pyinstaller.exe" --onefile --icon=RogueReader.ico --noconsole RogueReader.py

:: Notify user upon completion
if exist "dist\RogueReader.exe" (
    echo Conversion to .exe completed successfully!
    echo You can find your executable in the dist folder.
) else (
    echo Conversion failed. Check the output for errors.
)

:: Pause the script to allow the user to see the output
pause
