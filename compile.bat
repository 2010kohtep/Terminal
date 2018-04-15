@echo off
del Terminal.asi
dcc32_d7 -Q System.pas SysInit.pas -M -Y -Z -$D-
dcc32_d7 -Q Terminal.dpr -$O+
pause
cls