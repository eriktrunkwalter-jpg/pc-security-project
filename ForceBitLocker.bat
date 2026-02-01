@echo off
REM ForceBitLocker.bat
REM Purpose: Automate BitLocker on non-TPM system with specific password
REM --------------------------------------------------------------------

REM 1. Set Registry Policies (Again, to be sure)
reg add "HKLM\SOFTWARE\Policies\Microsoft\FVE" /v UseEnhancedPin /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\FVE" /v AllowMbaWithoutTpm /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\FVE" /v EnableBDEWithNoTPM /t REG_DWORD /d 1 /f

REM 2. Add Password Protector (Using Pipe)
REM Note: ! needs escaping if delayed expansion is on, but here it is off by default.
REM We redirect stderr to stdout to catch errors.
echo ErikTrunkwalter13092002!| manage-bde -protectors -add C: -pw > "%USERPROFILE%\Documents\BL_Setup_Log.txt" 2>&1

REM 3. Enable BitLocker with Recovery Password
manage-bde -on C: -rp -skiphardwaretest >> "%USERPROFILE%\Documents\BL_Setup_Log.txt" 2>&1

REM 4. Export Key (Wait a bit for changes to propagate)
timeout /t 5 /nobreak > nul
manage-bde -protectors -get C: > "%USERPROFILE%\Documents\BitLocker_Recovery_Key.txt"

REM 5. Verify
type "%USERPROFILE%\Documents\BL_Setup_Log.txt"
