@echo off
call "%~dp0tools\Find_Godot.cmd"
if errorlevel 1 exit /b 1
for %%T in (footprint_checks story_checks gait_checks crowd_checks) do (
 "%DEMO_ENGINE%" --headless --path "%~dp0." --fixed-fps 60 --script res://tests/v41/%%T.gd
 if errorlevel 1 exit /b 1
)
"%DEMO_ENGINE%" --headless --path "%~dp0." --script res://tests/v41/story_checks.gd -- --restore-fixture
exit /b %errorlevel%
