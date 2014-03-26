{$S-}{&CDecl+}
uses Use32,Os2Def,OS2MM,Os2Base,CRT,DART,waveunit;

var
  WS : TWavStream;


procedure GetBuf(BNum : integer);
var i : longint;
begin
  Dec(ulBuffersToGo);
  if ulBuffersToGo=0 then
  begin
    MixBuffers[bNum].ulFlags := MIX_BUFFER_EOS;
    fillchar(MixBuffers[bNum].pBuffer^, BufferParms.ulBufferSize, 0);
    {in order not to have click at the end}
  end;
  WS.ReadPCM(MixBuffers[bNum].pBuffer^, BufferParms.ulBufferSize);
end;


begin
  if ParamCount = 0 then
  begin
    WriteLn('Plays WAV files using DART v0.1');
    Writeln('Supports ADPCM, MULAW and ALAW compression');
    WriteLn('(c) Michael L. Gorodetsky');
    WriteLn('Usage: WAVPLAY <filename.wav>');
    WriteLn;
    Halt(1);
  end;

  DARTBufSize := 8192; 
  DARTNumBufs := 16;

  (* Load the audio file and setup for playback. *)
  WS:=TWavStream.Open(ParamStr(1));
  if WS.Status <> stOk then Halt;
  DEFAULT_16bit := true;

  if not InitAmpMix(@WS.PCMFileFormat.wf, MCI_PLAY) then Halt;
  if not SetDART(MCI_Play, GetBuf, nil, WS.DecodedSize) then Halt;

  WriteLn('Playing, Press Esc to stop');
  StartPlayBack;
  repeat
    DosSleep(50); {Awake every 0.05s}
  until (Keypressed and (ReadKey=#27)) or (StopSound);
  StopPlay:=True;
  repeat until StopSound;

  DoneAmpMix;
  WS.Destroy;
end. (* end main *)


