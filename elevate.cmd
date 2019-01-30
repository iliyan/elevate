:: Check if running As Admin (Elevated) using a known Admin-only command
@echo off
fsutil dirty query %SystemDrive% >nul

:: Already elevated?
if %errorlevel% equ 0 (
    goto START
)

:: Prepare debugging options, if necessary
setlocal
if not "%ELEVATE_DEBUG%" == "" (
    set _mode=%ELEVATE_DEBUG%
    set _comspec=/k
    echo on
) else (
    set _mode=0
    set _comspec=/c
)

:: Create and run a temporary VBScript to execute the batch file you are currently reading with
:: elevated permissions
set _cwd=%CD:"=""%
set _timestamp=------- %date% %time% -------
set _output=%_cwd%\~elevate.out
set _lock=%_cwd%\~elevate.lock
set _elevator=%temp%\~elevate.vbs
set _elevated=%~f0
set _argv=%*

:: Double up any quotes in order to conform to VBS quoting rules
set _elevated=""%_elevated%""
set _argv=%_argv:"=""%

echo %_timestamp% >"%_output%"
if not "%ELEVATE_DEBUG%" == "" (
    echo WScript.Echo "Running: %COMSPEC%", "%_comspec%  ""%_elevated% %_comspec% %_cwd% %_argv%""", "%_cwd%", "runas", %_mode% >> "%_output%"
)

echo %_timestamp% >"%_lock%"
echo Set UAC = CreateObject^("Shell.Application"^) > "%_elevator%"
echo UAC.ShellExecute "%COMSPEC%", "%_comspec%  ""%_elevated% %_comspec% %_cwd% %_argv%""", "%_cwd%", "runas", %_mode% >> "%_elevator%"
cscript "%_elevator%" //NoLogo

:: We must wait since our elevated twin executes asynchronously.
:: BEWARE: Waiting is currently indefinitely long for simplicity
:WAIT_AND_CHECK_LOCKFILE
ping -n 6 127.0.0.1 >nul
if not exist "%_lock%" (
    :: Relate any output the elevated twin might have produced
    type %_output%
    del /f /q "%_output%" >nul
    exit /B
)
goto WAIT_AND_CHECK_LOCKFILE

:START
:: Set the debugging helper
set _comspec=%1
shift /1
if "%_comspec%" == "/k" (echo on)

:: Set the current directory to the location that was current before elevation
cd /d %1
shift /1

:: Place the code which requires Admin/elevation below
set _cwd=%CD:"=""%
set _output=%_cwd%\~elevate.out
set _lock=%_cwd%\~elevate.lock

:: Create a lock file to test when determining is elevation has completed
call %COMSPEC% /c %1 %2 %3 %4 %5 %6 %7 %8 %9  >>%_output% 2>&1 | type %_output%
del /f /q "%_lock%" >nul
