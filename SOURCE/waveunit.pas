{$A-}{$S-}{&CDecl+}
unit WAVEUNIT;

interface
{$IFDEF WIN32}
uses mmsystem, windows, Classes;
{$ELSE}
uses Os2Def,Os2mm, Classes;
{$ENDIF}

const
  DEFAULT_16bit : Boolean = True;

type WBuf = Array[0..8192] of smallint;
     PWBuf = ^WBuf;
     BBuf = Array[0..8192] of shortint;
     PBBuf = ^BBuf;


{$IFDEF VirtualPascal}
const
  SEEK_SET = 0;
  SEEK_CUR = 1;
  SEEK_END = 2;
{$ENDIF}

const
  bsOk = 0;
  bsInvFormat = 1;
  bsReadError = 2;
  swNotRiff = $400;
  swNotWave = $401;
  swNot_fmt = $402;
  swNotData = $403;
  swNot_PCM = $404;
  swNoMemory = $405;
  stOK = 0;
  stMono = 1;
  stStereo = 2;
  st8bit = 1;
  st16bit = 2;

const
  UNKNOWN = $0000;
  WAVEPCM = $0001;                {Pulse Code Modulation           }
  MSADPCM = $0002;                {Microsoft Corporation           }
  IBM_CVSD = $0005;               {IBM Corporation                 }
  ALAW = $0006;                   {Microsoft Corporation           }
  MULAW = $0007;                  {Microsoft Corporation           }
  OKI_ADPCM = $0010;              {OKI                             }
  IMA_ADPCM = $0011;              {Intel Corporation               }
  DVI_ADPCM = IMA_ADPCM;          {Intel Corporation               }
  MEDIASPACE_ADPCM = $0012;       {Videologic                      }
  SIERRA_ADPCM = $0013;           {Sierra Semiconductor Corp       }
  G723_ADPCM = $0014;             {Antex Electronics Corporation   }
  DIGISTD = $0015;                {DSP Solutions, Inc.             }
  DIGIFIX = $0016;                {DSP Solutions, Inc.             }
  DIALOGIC_OKI_ADPCM = $0017;     {Dialogic Corporation            }
  YAMAHA_ADPCM = $0020;           {Yamaha Corporation of America   }
  SONARC = $0021;                 {Speech Compression              }
  TRUESPEECH = $0022;             {DSP Group, Inc                  }
  ECHOSC1 = $0023;                {Echo Speech Corporation         }
  AUDIOFILE_AF36 = $0024;         {                                }
  APTX = $0025;                   {Audio Processing Technology     }
  AUDIOFILE_AF10 = $0026;         {                                }
  DOLBY_AC2 = $0030;              {Dolby Laboratories              }
  GSM610 = $0031;                 {Microsoft Corporation           }
  ANTEX_ADPCME = $0033;           {Antex Electronics Corporation   }
  CONTROL_RES_VQLPC = $0034;      {Control Resources Limited       }
  DIGIREAL = $0035;               {DSP Solutions, Inc.             }
  DIGIADPCM = $0036;              {DSP Solutions, Inc.             }
  CONTROL_RES_CR10 = $0037;       {Control Resources Limited       }
  NMS_VBXADPCM = $0038;           {Natural MicroSystems            }
  CS_IMAADPCM = $0039;            {Crystal Semiconductor IMA ADPCM }
  G721_ADPCM = $0040;             {Antex Electronics Corporation   }
  MPEG = $0050;                   {Microsoft Corporation           }
  IBMMULAW = $0101;               { IBM mu-law format              }
  IBMALAW = $0102;                { IBM a-law format               }
  IBMADPCM = $0103;               { IBM AVC Adaptive Differential  }
  CREATIVE_ADPCM = $0200;         {Creative Labs, Inc              }
  CREATIVE_FASTSPEECH8 = $0202;   {Creative Labs, Inc              }
  CREATIVE_FASTSPEECH10 = $0203;  {Creative Labs, Inc              }
  FM_TOWNS_SND = $0300;           {Fujitsu Corp.                   }
  OLIGSM = $1000;                 {Ing C. Olivetti & C., S.p.A.    }
  OLIADPCM = $1001;               {Ing C. Olivetti & C., S.p.A.    }
  OLICELP = $1002;                {Ing C. Olivetti & C., S.p.A.    }
  OLISBC = $1003;                 {Ing C. Olivetti & C., S.p.A.    }
  OLIOPR = $1004;                 {Ing C. Olivetti & C., S.p.A.    }
  DEVELOPMENT = $FFFF;            {Developer's temporary           }

type
  dwName = array[1..4] of Char;

  Chunk = record
            Name : dwName;
            Size : LongInt;
          end;


const                             {chunk names}
  RiffName : dwName = 'RIFF';
  WaveName : dwName = 'WAVE';
  DataName : dwName = 'data';
  Fmt_Name : dwName = 'fmt ';
  FactName : dwName = 'fact';
  Cue_Name : dwName = 'cue ';
  PlstName : dwName = 'plst';

type iCoeff = record
                iCoef1,
                iCoef2 : Smallint;
              end;

  ADPCMCOEFSET = array[0..6] of iCoeff;


type
  WAVEFORMAT = record
                 wFormatTag : Word;         { Format category              }
                 wChannels : Word;          { Number of channels           }
                 dwSamplesPerSec : LongInt; { Sampling rate                }
                 dwAvgBytesPerSec : LongInt;{ For buffer estimation        }
                 wBlockAlign : Word;        { Data block size for PCM      }
               end;

  {for pcm formats}
  PCMWAVEFORMAT = record
                 wFormatTag : Word;         { Format category              }
                 wChannels : Word;          { Number of channels           }
                 dwSamplesPerSec : LongInt; { Sampling rate                }
                 dwAvgBytesPerSec : LongInt;{ For buffer estimation        }
                 wBlockAlign : Word;        { Data block size for PCM      }
                 wBitsPerSample : Word;     { Sample size, 0 if unused     }
               end;

  type PPCMWAVEFORMAT=^PCMWAVEFORMAT;

  {all nonpcm formats}
  WAVEFORMATEX = record
                 wFormatTag : Word;         { Format category              }
                 wChannels : Word;          { Number of channels           }
                 dwSamplesPerSec : LongInt; { Sampling rate                }
                 dwAvgBytesPerSec : LongInt;{ For buffer estimation        }
                 wBlockAlign : Word;        { Data block size for PCM      }
                 wBitsPerSample : Word;     { Sample size, 0 if unused     }
                 cbSize : Word;             {Size of additional information}
               end;


  ADPCMWAVEFORMAT = record
                      wfx : WAVEFORMATEX;
                      wSamplesPerBlock : Word;
                        {(((nBlockAlign-7*nChannels)*8)/(wBitsPerSample*nChannels))+2}
                      wNumCoef : Word;
                        {Count of the number of coefficient sets defined in aCoef}
                      aCoef : ADPCMCOEFSET;
                        {These are the coefficients used by the wave to play.
                         They may be interpreted as fixed point 8.8 signed
                         values. Currently there are 7 preset coefficient sets.
                         They must appear in the following order.}
                    end;

  PWAVEFORMATEX = ^WAVEFORMATEX;
  PADPCMWAVEFORMAT = ^ADPCMWAVEFORMAT;

  FactRec = record                {Required for all but PCM      }
              FileSize : LongInt;
            end;

  CueRec = record
             CuePoints : LongInt;
           end;

  CuePointRec = record
                  Name : dwName;
                  Position : LongInt;
                  fccChunk : dwName;
                  ChunkStart : LongInt;
                  BlockStart : LongInt;
                  SampleOffset : LongInt;
                end;

  PlstRec = record
              Segments : LongInt;
            end;

  SegmRec = record
              Name : dwName;
              Length : LongInt;
              Loops : LongInt;
            end;

  AdpcmBlockHeaderM = record
                        bPredictor : Byte;
                        iDelta, iSampl1, iSampl2 : Smallint;
                      end;

  AdpcmBlockHeaderS = record
                        bPredictor_l, bPredictor_r : Byte;
                        iDelta_l, iDelta_r,
                        iSampl1_l, iSampl1_r,
                        iSampl2_l, iSampl2_r : Smallint;
                      end;

   PCMFileHeader = record
                     RiffChunk : chunk;
                     WaveName : dwName;
                     fmtChunk : chunk;
                     wf : PCMWAVEFORMAT;
                     dataChunk : chunk;
                   end;


  TCodec = class;


  TWavStream = class(TStream)
               private
                 FHandle : hmmio;
                 DataStart,
                 DataSize,
                 DecodedDataSize,
                 TotalBlocks,
                 FileSize : LongInt;
                 AccessMode : Word;       {read or write}
                 Codec : TCodec;
               public
                 Status : integer;
                 Format : ADPCMWAVEFORMAT;
                 PCMFileFormat : PCMFileHeader;
                 constructor Open(FileName : string);
                 constructor Create(FileName : string; PPCMH : PPCMWaveFORMAT;
                                    Size : longint);
                 function Read(var Buffer; Count: Longint): Longint; virtual;
                 function Write(const Buffer; Count: Longint): Longint; virtual;
                 function Seek(Offset : Longint; Origin : word) : Longint; virtual;
                 procedure MakePCMHeader(PPCMH : PPCMWaveFORMAT);
                 function ReadPCM(var Buffer; Count: Longint): Longint; virtual;
                 destructor Destroy;
                 property Handle : Longint read FHandle;
                 property Size  : Longint read DataSize;
                 property DecodedSize  : Longint read DecodedDataSize;
                 property Blocks : Longint read TotalBlocks;
               end;


  TCodec = class(TObject)
  private
    FHandle : hmmio;
    PInBuf, POutBuf : PBBuf;
    TotalData,
    InBlockSize,
    OutBlockSize : longint;
    BufPos,
    EndPos : longint;
    {Stream : TWavStream;}
  public
    constructor Create(WSrc : TWavStream); virtual;
    function Read(var Buffer; Count: Longint): Longint; virtual;
   { function Write(const Buffer; Count: Longint): Longint; virtual; abstract; }
(*    {$IFDEF WIN32}
    destructor Destroy; override;
    {$ELSE} *)
    destructor Destroy; virtual;
(*    {$ENDIF}*)
   end;


var ErrorMessage : String;

implementation

{$I MSADPCM.INC}
{$I AMULAW.INC}

{$IFDEF WIN32}
function mmioFourCC( ch0, ch1, ch2, ch3: Char ): uLong;
begin
  Result := ord(ch0) or (ord(ch1) shl 8) or
            (ord(ch2) shl 16) or (ord(ch3) shl 24);
end;
{$ENDIF}


var BufChunk : Chunk;
    FactChunk : FactRec;
    CueChunk : CueRec;
    PlstChunk : PlstRec;


  procedure ErrorMsg(Error : Ulong); far;
  begin
    case Error of
      swNotRiff, swNotWave,
      swNot_fmt, swNotData : ErrorMessage := ErrorMessage+', unknown format';
      swNot_PCM            : ErrorMessage := ErrorMessage+', not PCM format';
    end;
    WriteLn('Error: '+ErrorMessage);
  end;

  constructor TCodec.Create(WSrc : TWavStream);
  begin
    FHandle:=WSrc.Handle;
    TotalData:=WSrc.Size
  end;

  function TCodec.Read(var Buffer; Count: Longint): Longint;
  begin
    Result:=mmioRead(fhandle,@Buffer,Count);
  end;

  destructor TCodec.Destroy;
  begin
  end;

  procedure TWavStream.MakePCMHeader(PPCMH : PPCMWaveFORMAT);
  begin
    with PCMFileFormat do
    begin
      RiffChunk.name :='RIFF';
      WaveName :='WAVE';
      fmtChunk.name :='fmt ';
      fmtChunk.size := 16;
      dataChunk.name :='data';
      with wf do
      begin
        wFormatTag := WAVEPCM;
        wChannels := PPCMH^.wChannels;
        dwSamplesPerSec := PPCMH^.dwSamplesPerSec;
        wBitsPerSample := PPCMH^.wBitsPerSample;
        wBlockAlign := (wBitsPerSample div 8)*wChannels;
        dwAvgBytesPerSec := dwSamplesPerSec*wBitsPerSample*wChannels div 8;
      end;
    end;
  end;


  function StrPChar(var St : String) : Pchar;
  begin
    if Length(st)<255 then St[Length(St)+1]:=#0;
    StrPChar:=@St[1];
  end;

  constructor TWavStream.Open(FileName : string);
    {var CurrPos : LongInt;}
  {$IFDEF WIN32}
  type mmckinfo=tmmckinfo;
  {$ENDIF}
  var ckRiff, ckfmt : mmckinfo;
     tFileName : string;

  begin
    tFileName:=FileName;
    Status:=-1;
   {$IFDEF WIN32}
    FHandle:=mmioOpen(StrPChar(tFileName), nil, MMIO_Read or MMIO_ALLOCBUF);
   {$ELSE}
    FHandle:=mmioOpen(StrPChar(tFileName), nil, MMIO_Read or
      MMIO_NOIDENTIFY or MMIO_ALLOCBUF);
   {$ENDIF}

    if fhandle=0 then Exit;

        fillchar(CkRiff, sizeof(mmckinfo ), 0 );

        CkRiff.fccType := mmioFOURCC('W','A','V','E');
        if mmioDescend(fhandle, @CkRiff, nil, MMIO_FINDRIFF) <> 0 then
        begin
          mmioClose(fhandle,0);
          ErrorMsg(swNotWave);
          Exit;
        end;
        FileSize := CkRiff.ckSize+8;

        fillchar(Ckfmt, sizeof( mmckinfo ), 0 );
        Ckfmt.ckid := mmioFOURCC('f','m','t',' ');
        if mmioDescend(fhandle, @Ckfmt, @CkRIFF, MMIO_FINDCHUNK) <> 0 then
        begin
          mmioClose(fhandle,0);
          ErrorMsg(swNot_fmt);
          Exit;
        end;

        mmioRead(fhandle,@Format.wfx, SizeOf(Format.wfx));
        if (Format.wfx.cbSize<=SizeOf(Format)-SizeOf(Format.wfx)) then
          mmioRead(fhandle,@Format.wSamplesPerBlock, Format.wfx.cbSize)
          else mmioRead(fhandle,@Format.wSamplesPerBlock,
            SizeOf(Format)-SizeOf(Format.wfx));

        mmioAscend(fhandle,@Ckfmt,0);

        mmioRead(fhandle,@BufChunk,SizeOf(BufChunk));
        if BufChunk.Name = FactName then
          begin
            mmioRead(fhandle,@FactChunk,SizeOf(FactRec));
            mmioSeek(fhandle,BufChunk.Size-SizeOf(FactRec),SEEK_CUR);
            mmioRead(fhandle,@BufChunk, SizeOf(BufChunk));
          end;
        if BufChunk.Name = Cue_Name then
          begin
            mmioRead(fhandle, @CueChunk, SizeOf(CueRec));
            mmioSeek(fhandle, BufChunk.Size-SizeOf(CueRec),SEEK_CUR);
            mmioRead(fhandle, @BufChunk, SizeOf(BufChunk));
          end;
        if BufChunk.Name = PlstName then
          begin
            mmioRead(fhandle,@PlstChunk, SizeOf(PlstRec));
            mmioSeek(fhandle,BufChunk.Size-SizeOf(PlstRec),SEEK_CUR);
            mmioRead(fhandle,@BufChunk, SizeOf(BufChunk));
          end;

        if BufChunk.Name <> DataName then
        begin
          fillchar(Ckfmt, sizeof( mmckinfo ), 0 );
          Ckfmt.ckid := mmioFOURCC('d','a','t','a');
          if mmioDescend(fhandle, @Ckfmt, @CkRIFF, MMIO_FINDCHUNK) <> 0 then
          begin
            mmioClose(fhandle,0);
            ErrorMsg(swNotdata);
            Exit;
          end;
        end;

        with Format.wfx do
          begin
            if dwSamplesPerSec = 0 then
             begin
               ErrorMsg(swNotWave);
               Exit;
             end;
             DataSize  := BufChunk.Size;
             DataStart := mmioSeek(fhandle,0,SEEK_CUR);
             TotalBlocks := Size div wBlockAlign;
             AccessMode := MMIO_Read;
          end;

      case Format.wfx.wFormatTag of
        MSADPCM : Codec:=MSADPCM_Codec.Create(Self);
        ALAW, MULAW : Codec:=AMULAW_Codec.Create(Self);
        else Codec:=TCodec.Create(Self);
      end;
      if Codec=nil then ErrorMsg(swNot_fmt);
      DecodedDataSize:=Codec.TotalData;
      MakePCMHeader(@Format.wfx);
      with PCMFileFormat do
      begin
        RiffChunk.Size := DecodedDataSize+SizeOf(PCMFileHeader)-SizeOf(chunk);
        dataChunk.Size := DecodedDataSize;
        with wf do
        begin
          if Format.wfx.wFormatTag <> WAVEPCM then
          if DEFAULT_16bit then
          wBitsPerSample := 16 else wBitsPerSample := 8;
          wBlockAlign := (wBitsPerSample div 8)*wChannels;
          dwAvgBytesPerSec := dwSamplesPerSec*wBitsPerSample*wChannels div 8;
        end;
      end;
    Status:=stOK;
  end;

  function TWavStream.Seek(Offset : Longint; Origin : word) : Longint;
  begin

    case Origin of
    Seek_Cur :
      begin
        Result:=mmioSeek(fhandle,Offset,SEEK_CUR);
        if Result>DataStart+DataSize then
          Result:=mmioSeek(fhandle,DataStart+DataSize,SEEK_SET)-DataStart
        else
          Result:=Result-DataStart;
      end;
    Seek_End :
      if Offset<DataSize then
        Seek:=mmioSeek(fhandle,DataStart+DataSize-Offset,SEEK_SET)-DataStart else
        Seek:=mmioSeek(fhandle,DataStart,SEEK_SET)-DataStart;
      else {Seek_Set}
        if Offset<DataSize then
          Seek:=mmioSeek(fhandle,DataStart+Offset,SEEK_SET)-DataStart else
          Seek:=mmioSeek(fhandle,DataStart+DataSize,SEEK_SET)-DataStart;
    end;
  end;


  constructor TWavStream.Create(FileName : string;
                                PPCMH : PPCMWaveFORMAT;
                                Size : longint);
  {var CurrPos : LongInt;}
  {$IFDEF WIN32}
  type mmckinfo=tmmckinfo;
  {$ENDIF}
  var tFileName : string;

  begin
    tFileName:=FileName;
    Status:=-1;
   {$IFDEF WIN32}
    FHandle:=mmioOpen(StrPChar(tFileName), nil, MMIO_Create or MMIO_Write
                       or MMIO_ALLOCBUF);
   {$ELSE}
    FHandle:=mmioOpen(StrPChar(tFileName), nil, MMIO_Create or MMIO_Write
                       or MMIO_NOIDENTIFY or MMIO_ALLOCBUF);
   {$ENDIF}

    AccessMode:=MMIO_Create;
    if fhandle=0 then Exit;
    MakePCMHeader(PPCMH);
    PCMFileFormat.RiffChunk.Size := Size+SizeOf(PCMFileHeader)-SizeOf(chunk);
    PCMFileFormat.dataChunk.Size := Size;
    MOVE(PCMFileFormat.wf, Format, SizeOf(PCMWaveFormat));
    Write(PCMFileFormat, SizeOf(PCMFileHeader));
    Status:=stOK;
  end;


  function TWavStream.Read(var Buffer; Count : LongInt) : longint;
  begin
    Result:=mmioRead(fhandle,@Buffer,Count);
  end;

  function TWavStream.ReadPCM(var Buffer; Count : LongInt) : longint;
  begin
    Result:=Codec.Read(Buffer, Count)
  end;

  function TWavStream.Write(const Buffer; Count : LongInt) : longint;
  begin
    Write:=mmioWrite(fhandle,@Buffer,Count);
  end;

  destructor TWavStream.Destroy;
  begin
    if (AccessMode=MMIO_Create) and
      (PCMFileFormat.DataChunk.Size=0) then
    with PCMFileFormat do
    begin
      mmioFlush(fhandle,0);
      DataChunk.Size:=mmioSeek(fhandle,0,Seek_End)-SizeOf(PCMFileHeader);
      RiffChunk.Size := DataChunk.Size+SizeOf(PCMFileHeader)-SizeOf(chunk);
      mmioSeek(fhandle,0,Seek_Set);
      mmioWrite(fhandle,@PCMFileFormat, SizeOf(PCMFileHeader));
    end;
    mmioClose(fhandle,0);
    if Codec<>nil then Codec.Destroy;
  end;

  function pcmIsValidFormat(lpwfx : PWAVEFORMATEX) : Boolean;
  begin
    pcmIsValidFormat := False;
    if lpwfx = nil then Exit;
    if lpwfx^.wFormatTag <> WAVEPCM then Exit;
    if ((lpwfx^.wBitsPerSample <> 8) and
        (lpwfx^.wBitsPerSample <> 16)) then Exit;
    if ((lpwfx^.wChannels < 1) or
        (lpwfx^.wChannels > 2)) then Exit;
    if ((lpwfx^.dwSamplesPerSec <> 44100) and
        (lpwfx^.dwSamplesPerSec <> 22050) and
        (lpwfx^.dwSamplesPerSec <> 11025)) then Exit;
    pcmIsValidFormat := True;
  end;

end.
