{$S-}{&CDecl+}
uses Use32,OS2MM,Os2Def,Os2Base,CRT,DART,waveunit;

var
  WS : TWavStream;

procedure PutBuf(BNum : integer);
begin
  Dec(ulBuffersToGo);
  if ulBuffersToGo=1 then
  begin
    if bnum<pred(ulNumBuffers) then
    MixBuffers[Succ(bNum)].ulFlags := MIX_BUFFER_EOS
    else MixBuffers[0].ulFlags := MIX_BUFFER_EOS;
  end;
  WS.Write(MixBuffers[bNum].pBuffer^, BufferParms.ulBufferSize);
end;


var DumbHeader : PCMWaveFormat;

begin
  if ParamCount = 0 then
  begin
    WriteLn('Records WAV file using DART v0.1');
    WriteLn('(c) Michael L. Gorodetsky');
    WriteLn('Usage: WAVREC <filename.wav>');
    WriteLn;
    Halt(1);
  end;

  DARTBufSize := 8192;
  DARTNumBufs := 16;

  With DumbHeader do
  begin
    wChannels:=1;
    dwSamplesPerSec:=22050;
    wBitsPerSample:=16;
  end;

  WS:=TWavStream.Create(ParamStr(1),@DumbHeader,0);
  if WS.Status <> stOk then Halt;
  if not InitAmpMix(@WS.PCMFileFormat.wf, MCI_RECORD) then Halt;
  if not SetDART(MCI_Record, nil, PutBuf, 1000000) then Halt;

  WriteLn('Recording, Press Esc to stop');

  StartRecord;
  repeat
    DosSleep(50); {Awake every 0.05s}
  until (Keypressed and (ReadKey=#27)) or (StopSound);
  StopRecord:=True;
  repeat until StopSound;

  DoneAmpMix;
  WS.Destroy;
end. (* end main *)


