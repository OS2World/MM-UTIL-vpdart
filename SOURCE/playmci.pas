{$IFDEF WIN32}
uses mmsystem, windows, sysutils;
{$ELSE}
uses os2mm, OS2Def;
{$ENDIF}

var StrS : String; 

{function mciSendString(pszCommandBuf: pChar; pszReturnString: pChar;
         wReturnLength: uShort; hwndCallBack: hwnd; usUserParm: uShort): Ulong;}

{pszCommandBuf  - buffer with MCI string,
 pszReturnString - return buffer,
 wReturnLength - rbuff size,
 hwndCallBack - callback window handle,
 usUserParm - user parameter}


procedure SString(var mciString : String);
var
  rc		: ULONG;

begin
  mciString[Length(mciString)+1]:=#0;
  {$IFDEF WIN32}
  rc:=mciSendString(@mciString[1],@mciString[1],0,0);
  {$ELSE}
  rc:=mciSendString(@mciString[1],@mciString[1],0,0,0);
  {$ENDIF}
  if rc<>0 then
  begin
    mciGetErrorString(rc, @mciString[1], 128);
    Writeln(PChar(@mciString[1]));
  end;
end;


begin
  if ParamCount=0 then 
  begin
    writeln('Usage: playmci <filename.wav>');
    halt;
  end;
  StrS:='open '+ ParamStr(1)+ ' type waveaudio alias snd wait';
  SString(StrS);
  StrS:='play snd wait';
  SString(StrS);
  StrS:='close snd wait';
  SString(StrS);
end.
