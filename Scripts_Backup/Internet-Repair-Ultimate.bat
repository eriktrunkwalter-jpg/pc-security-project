@echo off
:: ULTIMATE INTERNET REPAIR TOOL
:: Fixes Proxy, DNS, Winsock, and Firewall
:: Run as Administrator

echo Killing potentially blocking processes...
taskkill /F /IM tor.exe /T >nul 2>&1

echo.
echo [1/5] Disabling System Proxy (Registry)...
:: Disable Proxy in Current User
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f
:: Delete Proxy Server address
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /f >nul 2>&1
:: Disable Auto Detect
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v AutoConfigURL /t REG_SZ /d "" /f

echo.
echo [2/5] Resetting Network Stack...
netsh winsock reset
netsh int ip reset
netsh winhttp reset proxy

echo.
echo [3/5] Resetting DNS to DHCP (All Adapters)...
powershell -Command "Get-NetAdapter | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.InterfaceIndex -ResetServerAddresses }"

echo.
echo [4/5] Flushing DNS Cache...
ipconfig /flushdns
ipconfig /release
ipconfig /renew

echo.
echo [5/5] Resetting Firewall...
netsh advfirewall reset

echo.
echo ---------------------------------------------------
echo DONE! YOU MUST RESTART YOUR PC NOW.
echo ---------------------------------------------------
pause
