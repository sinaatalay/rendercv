Dim ans
ans = MsgBox( "Really uninstall TeX Live?" & vbcrlf & vbcrlf & _
  "Please make sure that no TeX Live programs are still running!", _
  36, "TeX Live uninstaller" )
If ans <> vbYes Then
  wscript.quit( 1 )
Else
  wscript.quit( 0 )
End If

' invocation from cmd.exe:
'   start /wait uninstq.vbs
' test errorlevel

' invocation from perl:
'   my $ans = system( "wscript", "uninstq.vbs" );
' 0 means yes