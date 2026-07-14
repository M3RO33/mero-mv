' MERO 포폴 업데이트 앱 실행기 (콘솔 창 없이 앱 창만 띄움)
Set sh = CreateObject("WScript.Shell")
p = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))
sh.Run "powershell -NoProfile -ExecutionPolicy Bypass -File """ & p & "updater-app.ps1""", 0, False
