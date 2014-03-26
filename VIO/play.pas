Program DAudio;
{$S-}{&CDecl+}
uses Use32,Os2Def,os2mm;

const
  STRING_LENGTH  = 128;
  MAX_BUFFERS    = 256;
  StopPlay : boolean = false;

{$I DART.INC}

const
  fPassedDevice         : BOOLEAN = TRUE;
  fRecording            : BOOLEAN = FALSE;

var
  rc            : ULONG;
  WavFileName   : String;


(***************************************************************************
 * Name        : LoadFile
 *
 * Description : Allocate application buffers for audio file and load
 *               audio file. These buffers will be copied to device
 *               buffers by another thread.
 *
 *               Before this procedure loads the audio file, the global
 *               MixSetupParms data structure is loaded with information
 *               from the audio files header.
 *
 *
 * Parameters  : CHAR szFilename[]     - Name of wave file to open
 *
 * Return      : BOOL   - TRUE  = failure
 *                      - FALSE = success
 *
 ***************************************************************************)


function AmpMixSetup(AudioHeader : OS2MM.MMAUDIOHEADER) : boolean;
begin
  (* Set the MixSetupParms data structure to match the loaded file.
   * This is a global that is used to setup the mixer. *)

  fillchar( MixSetupParms, sizeof( MCI_MIXSETUP_PARMS ), 0 );
   
  MixSetupParms.ulBitsPerSample :=
        AudioHeader.mmXWAVHeader.WAVEHeader.usBitsPerSample;
  MixSetupParms.ulFormatTag :=
        AudioHeader.mmXWAVHeader.WAVEHeader.usFormatTag;
  MixSetupParms.ulSamplesPerSec :=
        AudioHeader.mmXWAVHeader.WAVEHeader.ulSamplesPerSec;
  MixSetupParms.ulChannels :=
        AudioHeader.mmXWAVHeader.WAVEHeader.usChannels;

  (* Setup the mixer for playback of wave data *)
  MixSetupParms.ulFormatMode := MCI_PLAY;
  MixSetupParms.ulDeviceType := MCI_DEVTYPE_WAVEFORM_AUDIO;
  MixSetupParms.pmixEvent    := MyEvent;

  AmpMixSetup := mciCommand( usDeviceID, MCI_MIXSETUP,
                     MCI_WAIT or MCI_MIXSETUP_INIT,
                     MixSetupParms);
end;


Function LoadFile( szFileName:PChar ) : Boolean;
var
  mmAudioHeader         : OS2MM.MMAUDIOHEADER;
  hmmio                 : OS2MM.HMMIO;
  lBytesRead            : LONG;
  ulBufferOffset        : LONG;
  rc, ulIndex           : ULONG;


begin
  LoadFile:=false;
  (* Open the audio file. *)

  hmmio := mmioOpen( szFileName, nil, MMIO_READ or MMIO_DENYNONE );

  if hmmio=0 then begin
    Writeln('Unable to open wave file');
    LoadFile := false;
    exit;
  end;

  (* Get the audio file header. *)
   mmioGetHeader( hmmio, @mmAudioHeader, sizeof( MMAUDIOHEADER ),
                 @lBytesRead, 0, 0);
  
  if not AmpMixSetup(mmAudioHeader) then exit;

  (* Use the suggested buffer size provide by the mixer device
   * and the size of the audio file to calculate the required
   * number of Amp-Mixer buffers.
   * Note: The result is rounded up 1 to make sure we get the
   *       tail end of the file.
   *)
  ulNumBuffers :=
        mmAudioHeader.mmXWAVHeader.XWAVHeaderInfo.ulAudioLengthInBytes
        DIV MixSetupParms.ulBufferSize + 1;


  (* Set up the BufferParms data structure and allocate
   * device buffers from the Amp-Mixer *)

  BufferParms.ulNumBuffers := ulNumBuffers;
  BufferParms.ulBufferSize := MixSetupParms.ulBufferSize;
  BufferParms.pBufList := @MixBuffers;

  if not mciCommand( usDeviceID, MCI_BUFFER, MCI_WAIT or MCI_ALLOCATE_MEMORY,
                     BufferParms) then exit;

  (* Fill all device buffers with data from the audio file.*)
  for ulIndex := 0 to ulNumBuffers-1 do begin
    fillchar( MixBuffers[ ulIndex ].pBuffer^, BufferParms.ulBufferSize, 0 );
    MixBuffers[ ulIndex ].ulBufferLength := BufferParms.ulBufferSize;
    rc := mmioRead ( hmmio, MixBuffers[ ulIndex ].pBuffer,
                     MixBuffers[ ulIndex ].ulBufferLength );
  end;

  (* Set the "end-of-stream" flag
   *)
  MixBuffers[ulNumBuffers - 1].ulFlags := MIX_BUFFER_EOS;
  mmioClose( hmmio, 0 );
  LoadFile := true;
end;

  function StrPChar(var St : String) : Pchar;
  begin
    if Length(st)<255 then St[Length(St)+1]:=#0;
    StrPChar:=@St[1];
  end;

begin
   if ParamCount=0 then writeln('Usage: play <filename.wav>');
  (* Load the audio file and setup for playback. *)
   if not AmpMixOpen then exit;
   WavFileName:=ParamStr(1);
   LoadFile(StrPChar(WavFileName));
   StopPlay:=false;
   StartPlayBack;
   repeat until StopPlay;
   {readln;}
   AmpMixClose;
end. (* end main *)


