@echo off
:: THE MOST EPIC BATCH FILE EVER WRITTEN
title LAUNCHING ROGUEREADER - TURTLE POWER

:: Color for terminal (Green text on Black background)
color 0A

:: Display a Turtle Message Before Launch
echo ####################################################################
echo #                                                                  #
echo #            THE MIGHTY TURTLE IS PREPARING FOR LAUNCH...           #
echo #                                                                  #
echo ####################################################################

:: Countdown with progress bar
set /a countdown=5
set /a progress=0
:countdown_loop
if %countdown% GEQ 0 (
    set /a progress+=20
    set "progress_bar=[%progress%%%]"
    echo Launching in %countdown%... %progress_bar%
    ping -n 2 127.0.0.1 >nul 2>&1
    set /a countdown-=1
    goto countdown_loop
)

echo.

:: Announce the launch with the Turtle's blessing
echo THE TURTLE HAS SPOKEN! RogueReader is launching NOW!
ping -n 2 127.0.0.1 >nul 2>&1

:: Add a fake loading bar because it looks cool
echo Loading Python...  [                    ] 0%% 
ping -n 1 127.0.0.1 >nul
echo Loading Python...  [=====               ] 33%%
ping -n 1 127.0.0.1 >nul
echo Loading Python...  [===========         ] 66%%
ping -n 1 127.0.0.1 >nul
echo Loading Python...  [====================] 100%% 
ping -n 1 127.0.0.1 >nul

:: Path to the Python executable
set PYTHON_PATH=python
:: Path to your Python script
set SCRIPT_PATH="C:\Users\gooro\OneDrive\Desktop\RogueReader\RogueReader.py"

:: Verify if Python is installed
%PYTHON_PATH% --version
if %errorlevel% neq 0 (
    echo.
    echo ####################################################################
    echo # ERROR: Python is not installed or not in PATH!                   #
    echo # Please install Python or update the PATH variable.               #
    echo ####################################################################
    pause
    exit /b
)

:: Verify if the script exists
if not exist %SCRIPT_PATH% (
    echo.
    echo ####################################################################
    echo # ERROR: RogueReader script not found at %SCRIPT_PATH%!             #
    echo # Ensure that the script exists in the specified location.          #
    echo ####################################################################
    pause
    exit /b
)

:: Insert epic launch sequence here
echo Launching RogueReader in 3...2...1...
ping -n 2 127.0.0.1 >nul 2>&1

:: Launch the Python script
%PYTHON_PATH% %SCRIPT_PATH%

:: If Python fails, display an error
if %errorlevel% neq 0 (
    echo.
    echo ####################################################################
    echo # ERROR: Failed to launch RogueReader!                             #
    echo # Check your Python installation or script path.                   #
    echo ####################################################################
    pause
    exit /b
) else (
    echo.
    echo ####################################################################
    echo # SUCCESS: RogueReader has launched successfully!                  #
    echo ####################################################################
)

:: Add a "press any key to continue" prompt at the end
echo.
pause >nul
