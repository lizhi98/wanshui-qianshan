@echo off
call "%~dp0tools\Find_Godot.cmd"
if errorlevel 1 exit /b 1
"%DEMO_ENGINE%" --headless --path "%~dp0." --fixed-fps 60 --script res://tests/v413/animation_bindings.gd
if errorlevel 1 exit /b 1
"%DEMO_ENGINE%" --headless --path "%~dp0." --fixed-fps 60 --script res://tests/v413/lifecycle_checks.gd
if errorlevel 1 exit /b 1
"%DEMO_ENGINE%" --headless --path "%~dp0." --fixed-fps 60 --script res://tests/v413/march_clearance.gd
if errorlevel 1 exit /b 1
"%DEMO_ENGINE%" --headless --path "%~dp0." --fixed-fps 60 --script res://tests/v413/progress_checks.gd
if errorlevel 1 exit /b 1
for %%C in (A B C D) do (
 "%DEMO_ENGINE%" --headless --path "%~dp0." --fixed-fps 60 -- --animation-lab --lab-case=%%C
 if errorlevel 1 exit /b 1
)
python "%~dp0tools\Analyze_Animation_Motion.py"
exit /b %errorlevel%
