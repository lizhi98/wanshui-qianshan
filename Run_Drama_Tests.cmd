@echo off
call "%~dp0Run_Memorial_Tests.cmd"
if errorlevel 1 exit /b 1
"%DEMO_ENGINE%" --headless --path "%~dp0." --fixed-fps 60 --script res://tests/v412/director_checks.gd
if errorlevel 1 exit /b 1
"%DEMO_ENGINE%" --headless --path "%~dp0." --fixed-fps 60 --script res://tests/v412/salute_pose_checks.gd
exit /b %errorlevel%
