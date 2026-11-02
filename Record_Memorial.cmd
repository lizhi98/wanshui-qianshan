@echo off
call "%~dp0tools\Find_Godot.cmd"
if errorlevel 1 exit /b 1
"%DEMO_ENGINE%" --path "%~dp0." --resolution 1280x720 --fixed-fps 30 --write-movie "%~dp0Memorial_Full.avi" -- --memorial-replay --showcase
exit /b %errorlevel%
