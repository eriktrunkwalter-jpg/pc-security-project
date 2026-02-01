Set WshShell = WScript.CreateObject("WScript.Shell")

' 1. Launch with specific Title so we can grab focus
' We use 'start' to ensure a new window is created with the title
' Command: cmd /c "title BL_Setup && manage-bde -protectors -add C: -pw"
WshShell.Run "cmd.exe /c title BL_Setup && manage-bde -protectors -add C: -pw", 1, False

' 2. Loop until window exists (max 5 seconds)
For i = 1 To 10
    WScript.Sleep 500
    If WshShell.AppActivate("BL_Setup") Then Exit For
Next

' 3. Send Keys
WScript.Sleep 500
WshShell.SendKeys "ErikTrunkwalter13092002{!}"
WshShell.SendKeys "{ENTER}"

WScript.Sleep 1000
WshShell.SendKeys "ErikTrunkwalter13092002{!}"
WshShell.SendKeys "{ENTER}"

' Keep window open briefly to see result (optional, but command /c closes it)
WScript.Sleep 2000
