:: attempts to unblock the script and set the execution policy
:: Microsoft PowerShell.exe executable must be in the search path

:: do not echo command outputs to the console
@echo off

:: echo the instructions
echo ===========================================================
echo This batch file MUST be started with "Run as administrator"
echo ===========================================================
echo.

:: change the drive letter and path to the current folder
::  /d - change the drive letter together with the path
::   % - identifies a batch file variable
::   ~ - expands the path arguments
::   d - references the current drive
::   p - references the current path
::   0 - references the batch file (zeroth argument)
cd /d %~dp0

:: configure the settings
set script="%cd%\Start-CluesAdventure.ps1"
set access=RemoteSigned

:: unblock the script
echo Unblocked:  %script%
PowerShell.exe -Command "Unblock-File -Path '%script%'"

:: set the execution policy
echo Execution:  %access%
PowerShell.exe -Command "Set-ExecutionPolicy -ExecutionPolicy %access% -Force"

:: display a success or failure message
echo.
if     ["%errorlevel%"]==["0"] echo The updates were applied successfully
if not ["%errorlevel%"]==["0"] echo ERROR:  Start with "Run as administrator"

:: pause for reading
echo.
pause