{$IFDEF WIN32}
uses WAVEUNIT, mmsystem;
{$ELSE}
uses WAVEUNIT, os2mm;
{$ENDIF}


var WSIN, WSOUT : TWavStream;
    i : longint;
    TestBuffer : array[1..8192] of byte;

begin
  if ParamCount <> 2 then
  begin
    WriteLn('Converts MSADPCM to PCM .WAV files v0.1');
    WriteLn('(c) Michael L. Gorodetsky');
    WriteLn('Usage: WAVCONV <source.wav> <target.wav>');
    WriteLn;
    Halt(1);
  end;

  DEFAULT_16bit := true;
  WSIN:=TWavStream.Open(ParamStr(1));
  if WSIN.Status <> stOk then Halt(WSIN.Status);
  WSOUT:=TWavStream.Create(ParamStr(2),@WSIN.PCMFileFormat.wf,WSIN.DecodedSize);

  for i := 1 to  (WSIN.DecodedSize div SizeOf(TestBuffer)+1) do
    WSOUT.Write(TestBuffer, WSIN.ReadPCM(TestBuffer, SizeOf(TestBuffer)));

  WSOUT.Destroy;
  WSIN.Destroy;
end.
