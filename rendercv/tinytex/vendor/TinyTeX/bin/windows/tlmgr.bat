@echo off
rem Advanced launcher for tlmgr with auto-update
rem
rem Public Domain
rem Originally written 2009 by Tomasz M. Trzeciak

rem Make environment changes local
setlocal enableextensions

rem Get TL installation root (w/o trailing backslash)
set tlroot=%~dp0:
set tlroot=%tlroot:\bin\windows\:=%

rem check for any argument
if x == x%1 goto noargs

rem check for gui argument
set args=

:rebuildargs
shift
if x == x%0 goto nomoreargs
if gui == %0 goto guibailout
if -gui == %0 goto guibailout
if --gui == %0 goto guibailout
set args=%args% %0
goto rebuildargs

:nomoreargs

rem Remove remains of previous update if any
set tlupdater=%tlroot%\temp\updater-w32
if exist "%tlupdater%" del "%tlupdater%"
if exist "%tlupdater%" goto :err_updater_exists

rem Start tlmgr
set PERL5LIB=%tlroot%\tlpkg\tlperl\lib
path %tlroot%\tlpkg\tlperl\bin;%tlroot%\bin\windows;%path%
"%tlroot%\tlpkg\tlperl\bin\perl.exe" "%tlroot%\texmf-dist\scripts\texlive\tlmgr.pl" %args%

rem Finish if there are no updates to do; the last error code will be returned
if not exist "%tlupdater%" goto :eof
rem Rename updater script before it is run
move /y "%tlupdater%" "%tlupdater%.bat">nul
if errorlevel 1 goto :err_rename_updater
rem Run updater and don't return
"%tlupdater%.bat"

rem This should never execute
echo %~nx0: this message should never show up, please report it to tex-live@tug.org>&2
exit /b 1

:err_updater_exists
echo %~nx0: failed to remove previous updater script>&2
exit /b 1

:err_rename_updater
echo %~nx0: failed to rename "%tlupdater%">&2
exit /b 1

:noargs
echo No arguments given!

:guibailout
echo Use tlshell as a GUI for tlmgr.
pause
exit /b 1
