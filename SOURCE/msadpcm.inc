  { Next Delta = Delta * gaiP4[ this output ] / PSCALE }
const MSADPCM_gaiP4 : array[0..15] of Word = (230, 230, 230, 230,
                                              307, 409, 512, 614,
                                              768, 614, 512, 409,
                                              307, 230, 230, 230);

const
  MSADPCM_ACoef : ADPCMCOEFSET = ((iCoef1 : 256; iCoef2 : 0),
                                  (iCoef1 : 512; iCoef2 : -256),
                                  (iCoef1 : 0; iCoef2 : 0),
                                  (iCoef1 : 192; iCoef2 : 64),
                                  (iCoef1 : 240; iCoef2 : 0),
                                  (iCoef1 : 460; iCoef2 : -208),
                                  (iCoef1 : 392; iCoef2 : -232));


type
  MSADPCM_Codec = class(TCodec)
  private
    Channels,
    BitsPerSample : longint;
  public
    constructor Create(WSrc : TWavStream); override;
    function Read(var Buffer; Count: Longint): Longint; override;
    {function Write(const Buffer; Count: Longint): Longint; }
    function DecodeBlock(PSrc, PDst : PBBuf) : boolean;
    destructor Destroy; override;
  end;


constructor MSADPCM_Codec.Create(WSrc : TWavStream);
begin
  FHandle:=WSrc.Handle;
  Channels := WSrc.Format.wfx.wChannels;
  if DEFAULT_16bit then BitsPerSample := 16 else
    BitsPerSample := 8;
  InBlockSize:=WSrc.Format.wfx.wBlockAlign;
  OutBlockSize:=Channels*(BitsPerSample shr 3)*WSrc.Format.wSamplesPerBlock;
  TotalData:=OutBlockSize*WSrc.Blocks;
  GetMem(PInBuf,InBlockSize);
  GetMem(POutBuf,OutBlockSize);
  BufPos := OutBlockSize;
  EndPos := OutBlockSize;
end;


destructor MSADPCM_Codec.Destroy;
begin
  FreeMem(PInBuf,InBlockSize);
  FreeMem(POutBuf,OutBlockSize);
end;

function MSADPCM_Codec.Read(var Buffer; Count: Longint) : Longint;
var CountOut : longint;
    PBuf : PBBuf;

begin
  PBuf:=@Buffer;
  Result:=0;
  CountOut:=Count;
  repeat
    if (EndPos-BufPos)>CountOut then
      begin
        Move(POutBuf^[BufPos],PBuf^[0],CountOut);
        Result:=Result+CountOut;
        BufPos:=BufPos+CountOut;
        CountOut:=0;
      end
      else if EndPos>BufPos then
      begin
        Move(POutBuf^[BufPos],PBuf^[0],EndPos-BufPos);
        PBuf:=@PBuf^[EndPos-BufPos];
        Result:=Result+EndPos-BufPos;
        CountOut:=CountOut-(EndPos-BufPos);
        BufPos:=EndPos;
      end
      else
      begin
        if mmioRead(fhandle,@PInBuf^[0],InBlockSize) = 0 then CountOut:= 0
        else
        begin
          DecodeBlock(PInBuf, POutBuf);
          BufPos:=0;
        end;
      end;
    until CountOut=0;
  end;


function MSADPCM_Codec.DecodeBlock(PSrc, PDst : PBBuf) : boolean;
  var
    iInput, iNextInput : Smallint;
    iFirstNibble : Boolean;
    m, n : Word;
    aiSamp1, aiSamp2,
    aiCoef1, aiCoef2,
    aiDelta : array[0..1] of Smallint;
    PDInt : PWBuf absolute PDst;

  function DecodeNibble(iNibble : smallint) : integer;
  var lPrediction, lSamp : longint;
  begin
    lSamp := aiDelta[m];
    aiDelta[m] := (lSamp*MSADPCM_gaiP4[iInput and $0f]) div 256;
    if (aiDelta[m] < 16)
    then aiDelta[m] := 16;
    lPrediction := ((LongInt(aiSamp1[m])*aiCoef1[m])+
                       (LongInt(aiSamp2[m])*aiCoef2[m])) div 256;
    lSamp := (lSamp*iNibble)+lPrediction;
    if (lSamp > 32767) then lSamp := 32767
      else if (lSamp < -32768) then lSamp := -32768;
     aiSamp2[m] := aiSamp1[m];
     aiSamp1[m] := lSamp;
     DecodeNibble := lSamp;
  end;

  function GetInt(var pSrc : PBBuf) : integer;
  var PInt : ^Integer absolute pSrc;
  begin
    GetInt:=PInt^;
    pSrc:=@pSrc^[2];
  end;

  begin
    DecodeBlock := false;
    for m := 0 to Pred(Channels) do
      begin
        n:=pSrc^[0];
        pSrc:=@pSrc^[1];
        if (n >= 7) then Exit;
        aiCoef1[m] := MSADPCM_ACoef[n].iCoef1;
        aiCoef2[m] := MSADPCM_ACoef[n].iCoef2;
      end;

    for m := 0 to Pred(Channels) do aiDelta[m]:=GetInt(PSrc);
    for m := 0 to Pred(Channels) do aiSamp1[m]:=GetInt(PSrc);
    for m := 0 to Pred(Channels) do aiSamp2[m]:=GetInt(PSrc);

    if (BitsPerSample = 8) then
      begin
        for m := 0 to Pred(Channels) do
        begin
          pDst^[0]:=(aiSamp2[m] div 256+128);
          pDst:=@pDst^[1];
        end;
        for m := 0 to Pred(Channels) do
        begin
          pDst^[0]:=aiSamp1[m] div 256+128;
          pDst:=@pDst^[1];
        end;
      end
    else
      begin
        for m := 0 to Pred(Channels) do
        begin
          PDInt^[0]:=aiSamp2[m];
          pDst:=@pDst^[2];
        end;
        for m := 0 to Pred(Channels) do
        begin
          PDInt^[0]:=aiSamp1[m];
          pDst:=@pDst^[2];
        end;
      end;

    iFirstNibble := True;
    for n := 1 to OutBlockSize div (Channels*(BitsPerSample shr 3))-2 do
      begin
        for m := 0 to Pred(Channels) do
          begin
            if (iFirstNibble) then
              begin
                iNextInput:=pSrc^[0];
                pSrc:=@pSrc^[1];
                asm
                  mov     ax, iNextInput
                  cbw
                  sar     ax,4
                  mov     iInput, ax
                  mov     ax, iNextInput
                  sal     ax, 12
                  sar     ax, 12
                  mov     iNextInput, ax
                end;

                iFirstNibble := False;
              end
            else
              begin
                iInput := iNextInput;
                iFirstNibble := True;
              end;

           if BitsPerSample = 8 then
           begin
             PDst^[0]:=DecodeNibble(iInput) div 256+128;
             PDst:=@PDst^[1];
           end
           else
           begin
             PDInt^[0]:=DecodeNibble(iInput);
             pDst:=@pDst^[2];
           end;
            { PutInt(PDst, DecodeNibble(iInput));}
        end;
      end;
    DecodeBlock:=true;
  end;

