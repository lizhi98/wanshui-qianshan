@echo off
call "%~dp0tools\Find_Godot.cmd"
if errorlevel 1 exit /b 1
rem Active V3.3 player flow. Older reconstruction tests remain historical sources.
for %%T in (core campaign recon escort repair traversal relay recovery voice guidance) do (
  "%DEMO_ENGINE%" --headless --path "%~dp0." --script res://tests/v2/%%T_checks.gd
  if errorlevel 1 exit /b 1
)
"%DEMO_ENGINE%" --headless --path "%~dp0." --script res://tests/v2/carry_acceptance.gd
if errorlevel 1 exit /b 1
"%DEMO_ENGINE%" --headless --path "%~dp0." --script res://tests/v3/assault_checks.gd
if errorlevel 1 exit /b 1
for %%T in (climb_motion battle_checks) do (
  "%DEMO_ENGINE%" --headless --path "%~dp0." --script res://tests/v31/%%T.gd
  if errorlevel 1 exit /b 1
)
"%DEMO_ENGINE%" --headless --path "%~dp0." --script res://tests/v32/behavior_checks.gd
if errorlevel 1 exit /b 1
"%DEMO_ENGINE%" --headless --path "%~dp0." --script res://tests/v33/coordination_checks.gd
if errorlevel 1 exit /b 1
call "%~dp0Run_Snow_Tests.cmd"
exit /b %errorlevel%
