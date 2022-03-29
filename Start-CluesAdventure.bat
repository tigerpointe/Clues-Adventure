:: launches the script from a batch file
:: batch files can be double-clicked (unlike PowerShell scripts)
:: Microsoft PowerShell.exe executable must be in the search path

:: do not echo command outputs to the console
@echo off

:: change the drive letter and path to the current folder
::  /d - change the drive letter together with the path
::   % - identifies a batch file variable
::   ~ - expands the path arguments
::   d - references the current drive
::   p - references the current path
::   0 - references the batch file (zeroth argument)
cd /d %~dp0

:: start the script in PowerShell
:: use "&" for quoted paths that allow for spaces
PowerShell.exe -Command "& '%cd%\Start-CluesAdventure.ps1'"

:: pause on error
if not ["%errorlevel%"]==["0"] pause