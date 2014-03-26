{$N+}
{$S-}{&CDecl+}

{$IFDEF WIN32}
  uses waveunit;
{$ELSE}
  uses waveunit, os2mm;
{$ENDIF}

var
  WS : TWavStream;
  i : word;

begin
  WriteLn('WavInfo 0.1 (c) Michael L. Gorodetsky');
  WriteLn('Header info of WAV files');
  WriteLn('Usage: WaveView <filename.wav>');
  WriteLn;

  {MaxSampleRate := 11025;}
  if ParamCount = 0 then
    begin
      Halt(1);
    end;
  WS:=TWavStream.Open(ParamStr(1));
  {if WS.Status <> stOk then Halt(WS.Status);}
    Write  ('FormatTag:       ');
    with WS.Format.wfx do
    begin
    case wFormatTag of
      $0001 : Writeln('WAVEPCM');
      $0002 : Writeln('MSADPCM');
      $0006 : Writeln('ALAW');
      $0007 : Writeln('MULAW');
      $0011 : Writeln('IMA ADPCM');
      $0022 : Writeln('TRUESPEECH');
      $0031 : Writeln('GSM610');
      $0101 : Writeln('IBMMULAW');
      $0102 : Writeln('IBMALAW');
      $0103 : Writeln('IBMADPCM');
      $181C : Writeln('???');
    else
      Writeln(wFormatTag);
    end;
    Writeln('Channels:        ',wChannels);
    Writeln('SampleRate:      ',dwSamplesPerSec);

    Writeln('ByteRate:        ',dwAvgBytesPerSec);
    Writeln('BlockSize:       ',wBlockAlign);
    Writeln('BitsPerSample:   ',wBitsPerSample);
    Writeln('DataSize         ',WS.Blocks * WS.Format.wfx.wBlockAlign);
    if wFormatTag<>WAVEPCM then Writeln('Additional Size: ',cbSize);
    case wFormatTag of
      MSADPCM :
        begin
          With WS.Format do
          begin
            Writeln('SamplesPerBlock: ',wSamplesPerBlock);
            Writeln('NumCoeff:        ',wNumCoef);
            Writeln('ACoeff:');
            for i:=0 to 6 do
            Writeln('          ',ACoef[i].iCoef1:5,ACoef[i].iCoef2:5);
          end;
        end;
      IMA_ADPCM, GSM610 :
        begin
          With WS.Format do
            Writeln('SamplesPerBlock: ',wSamplesPerBlock);
        end;
      end;
    end;
    WS.Destroy;
end.
