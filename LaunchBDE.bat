@echo off
title BL_SETUP_WINDOW
echo READY
timeout /t 3 > nul
manage-bde -on C: -pw -rp -skiphardwaretest > C:\Users\Erik\Documents\BDE_Activation_Output.txt 2>&1
echo DONE (ErrorLevel: %errorlevel%)
timeout /t 5 > nul
exit
