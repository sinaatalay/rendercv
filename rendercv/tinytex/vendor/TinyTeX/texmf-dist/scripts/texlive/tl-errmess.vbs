option explicit

Dim wsh, envi

Set wsh = wscript.CreateObject("wscript.shell")
Set envi = wsh.environment("PROCESS")
MsgBox envi("RUNSCRIPT_ERROR_MESSAGE"), vbcritical, "Error"