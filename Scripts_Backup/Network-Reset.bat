@echo off
:: Network Factory Reset Script
echo Resetting Network Settings...

:: 1. Reset Winsock (TCP/IP Stack)
netsh winsock reset
netsh int ip reset

:: 2. Reset DNS to DHCP (Automatic)
:: Try common interface names
netsh interface ip set dns name="Wi-Fi" source=dhcp
netsh interface ip set dns name="Ethernet" source=dhcp
netsh interface ip set dns name="Ethernet 2" source=dhcp
netsh interface ip set dns name="WLAN" source=dhcp

:: 3. Clear DNS Cache
ipconfig /flushdns
ipconfig /registerdns

:: 4. Release and Renew
ipconfig /release
ipconfig /renew

echo.
echo -----------------------------------------------
echo NETWORK RESET COMPLETE. PLEASE RESTART PC NOW.
echo -----------------------------------------------
pause
