{$S-}{&CDecl+}
unit DART;

interface
uses Use32,Os2Def,Os2mm;

const
{DART}
  DARTBufSize : integer = 4096;
  DARTNumBufs : integer = 32;
  MAX_BUFFERS     = 256;
  MCI_BUFFER      = 62;
  MCI_MIXSETUP    = 63;
  MCI_MAX_COMMAND = 64;

{Constants for DART Callbacks}
  MIX_STREAM_ERROR    = $00000080;
  MIX_READ_COMPLETE   = $00000001;
  MIX_WRITE_COMPLETE  = $00000002;

{DART constants}
  MCI_MIXSETUP_INIT      = $00010000;
  MCI_MIXSETUP_DEINIT    = $00020000;
  MCI_MIXSETUP_QUERYMODE = $00040000;
  MCI_ALLOCATE_MEMORY    = $00040000;
  MCI_DEALLOCATE_MEMORY  = $00080000;
  MIX_BUFFER_EOS         = $00000001;

{DART structures}

type
  MCI_MIX_BUFFER = record
    ulStructLength : ulong;     { Structure length              }
    pBuffer        : pointer;   { Pointer to a buffer           }
    ulBufferLength : ulong;     { Length of the buffer          }
    ulFlags        : ulong;     { Flags                         }
    ulUserParm     : ulong;     { User parameter                }
    ulTime         : ulong;     { Device time in ms             }
    ulReserved1    : ulong;
    ulReserved2    : ulong;
  end;

 PMCI_MIX_BUFFER = ^MCI_MIX_BUFFER;

{DART Callbacks}

type
 PMIXERPROC   = function(ulHandle : ulong; pBuffer : PMCI_MIX_BUFFER; ulFlags : ulong) : long;
 PMIXEREVENT  = function(ulStatus : ulong; pBuffer : PMCI_MIX_BUFFER; ulFlags : ulong) : long;

 MCI_MIXSETUP_PARMS = record
   hwndCallback    : hwnd;       { Window handle                 }
   ulBitsPerSample : ulong;      { Bits per sample               }
   ulFormatTag     : ulong;      { Format tag                    }
   ulSamplesPerSec : ulong;      { Sampling rate                 }
   ulChannels      : ulong;      { Number of channels            }
   ulFormatMode    : ulong;      { Play or record                }
   ulDeviceType    : ulong;      { Device type                   }
   ulMixHandle     : ulong;      { Mixer handle                  }
   pmixWrite       : pmixerproc; { Entry point                   }
   pmixRead        : pmixerproc; { Entry point                   }
   pmixEvent       : pmixerevent;{ Entry point                   }
   pExtendedInfo   : pvoid;      { Extended information          }
   ulBufferSize    : ulong;      { Recommended buffer size       }
   ulNumBuffers    : ulong;      { Recommended number of buffers }
 end;


 PMCI_MIXSETUP_PARMS = ^MCI_MIXSETUP_PARMS;

 MCI_BUFFER_PARMS = record
    hwndCallback   : hwnd;
    ulStructLength : ulong;
    ulNumBuffers   : ulong;
    ulBufferSize   : ulong;
    ulMinToStart   : ulong;
    ulSrcStart     : ulong;
    ulTgtStart     : ulong;
    pBufList       : pvoid;
  end;



var
  usDeviceID            : USHORT;               (* Amp Mixer device id     *)
  ulCurrentBuf  : ULONG;                (* Current file buffer     *)
  ulBuffersToGo,
  ulNumBuffers          : ULONG;                (* Number of file buffers  *)
  MixBuffers            : Array[0..MAX_BUFFERS-1] of MCI_MIX_BUFFER;
                                                (* Device buffers          *)
  MixSetupParms         : MCI_MIXSETUP_PARMS;   (* Mixer parameters        *)
  BufferParms           : MCI_BUFFER_PARMS;     (* Device buffer parms     *)
  GenericParms          : MCI_GENERIC_PARMS;


type  BufProc = procedure(BNum : integer);
var   GetBuffer, PutBuffer : BufProc;
      StopSound, StopRecord, StopPlay : boolean;


(***************************************************************************
 * Name        : MciError
 * Description : Display a message box with the string corresponding to
 *               the passed mci error code.
 * Parameters  : ulError = mci error code
 * Return      : None
 ***************************************************************************)

var MciError : Procedure( ulError : ULONG );

type PWAVE_HEADER=^WAVE_HEADER;
                   {The same as PCMWAVEFORMAT, VP uses nonstandart names}

function  InitAmpMix(PAudioHeader : PWAVE_HEADER;
                     PlayRec     : ulong) : boolean;
function  DoneAmpMix : boolean;
procedure StartRecord;
Procedure StartPlayBack;
function mciCommand(usDeviceID: uShort; usMessage: uShort; ulParam1: uLong;
                    var Param2) : boolean;
Function SetDART(PlayRec : Ulong; GetBuf, PutBuf : BufProc;
                  Size : longint) : Boolean;

implementation

(***************************************************************************
 * Name        : DARTEvent The most important function for DART
 *
 * Description : The address to this procedure is passed to the mixer
 *               device in the MIX_SETUP_PARMS structure. The mixer
 *               device then calls this procedure when it has expended
 *               a buffer.
 *
 *               NOTE: This is a high priority thread. Too much code here
 *                     will bog the system down.
 *
 * Parameters  : ulStatus - Detailed error message
 *               pBuffer  - Pointer to expended buffer
 *               ulFlags  - Indicates the type of event
 *
 *
 * Return      : BOOL   - TRUE  = failure
 *                      - FALSE = success
 *
 ***************************************************************************)


Function DARTEvent ( ulStatus : ULONG;
                   pBuffer  : PMCI_MIX_BUFFER;
                   ulFlags  : ULONG ) : LONG; CDecl;
var i : longint;

begin
  case ulFlags of
    MIX_STREAM_ERROR or MIX_READ_COMPLETE ,  (* error occur in device *)
    MIX_STREAM_ERROR or MIX_WRITE_COMPLETE:  (* error occur in device *)
      if ulStatus = ERROR_DEVICE_UNDERRUN then begin
          { handle ERROR_DEVICE_UNDERRUN or OVERRUN here }
      end;

    MIX_READ_COMPLETE :                      (* for recording *)
       if ulBuffersToGo=0 then
       begin
         mciSendCommand( usDeviceID, MCI_STOP, MCI_WAIT, GenericParms, 0);
         StopSound:=true;
       end
       else
       begin
         if StopRecord then
         begin
           StopRecord:=false;
           ulBuffersToGo:=1;
           for i:=0 to pred(ulNumBuffers) do
           MixBuffers[i].ulFlags := MIX_BUFFER_EOS;
         end;

         if ulCurrentBuf<pred(ulNumBuffers) then
           MixSetupParms.pmixRead(MixSetupParms.ulMixHandle,
                                  @MixBuffers[Succ(ulCurrentBuf)], 1)
         else MixSetupParms.pmixRead(MixSetupParms.ulMixHandle,
                                  @MixBuffers, 1);
         if ulCurrentBuf<>0 then
           PutBuffer(pred(ulCurrentBuf)) else PutBuffer(pred(ulNumBuffers));
         if ulCurrentBuf<pred(ulNumBuffers) then inc(ulCurrentBuf)
           else ulCurrentBuf:=0;
       end;

    MIX_WRITE_COMPLETE:           (* for playback  *)
       if MixBuffers[ulCurrentBuf].ulFlags = MIX_BUFFER_EOS then
       begin
         mciSendCommand( usDeviceID, MCI_STOP, MCI_WAIT, GenericParms, 0 );
         StopSound:=true;
       end
       else
       begin
         if StopPlay then
         begin
           ulBuffersToGo:=0;
           for i:=0 to pred(ulNumBuffers) do
           MixBuffers[i].ulFlags := MIX_BUFFER_EOS;
         end;

         if ulCurrentBuf<pred(ulNumBuffers) then
           MixSetupParms.pmixWrite( MixSetupParms.ulMixHandle,
                                    @MixBuffers[ulCurrentBuf+1], 1)
         else
           MixSetupParms.pmixWrite( MixSetupParms.ulMixHandle,
                                    @MixBuffers, 1);
         if ulBuffersToGo>0 then if ulCurrentBuf<>0 then
           GetBuffer(pred(ulCurrentBuf)) else GetBuffer(pred(ulNumBuffers));
         if ulCurrentBuf<pred(ulNumBuffers) then inc(ulCurrentBuf)
           else ulCurrentBuf:=0;
       end;
  end;
  DARTEvent:=LONG( TRUE) ;
end; (* end MyEvent *)


Procedure DefaultMciError( ulError : ULONG );
var
  szBuffer      : Array[ 0..127] OF Char;
  rc            : ULONG;
begin
  rc := mciGetErrorString( ulError, szBuffer, 128);
  Writeln(szBuffer);
end;


function mciCommand(usDeviceID: uShort; usMessage: uShort; ulParam1: uLong;
                    var Param2) : boolean;
var
  rc            : ULONG;
begin
  rc:=mciSendCommand(usDeviceID, usMessage, ulParam1, Param2, 0);
  MciCommand := (rc=MCIERR_SUCCESS);
  if rc <> MCIERR_SUCCESS then MciError( rc );
end;



function InitAmpMix(PAudioHeader : PWave_Header;
                     PlayRec     : ulong) : boolean;

var
  AmpOpenParms          : MCI_AMP_OPEN_PARMS;
  AmpSetParms           : MCI_AMP_SET_PARMS;
  ConnectorParms        : MCI_CONNECTOR_PARMS;

begin
  (* open the mixer device *)
  fillchar( AmpOpenParms, sizeof( MCI_AMP_OPEN_PARMS ), 0 );
  AmpOpenParms.usDeviceID := 0;
  AmpOpenParms.pszDeviceType := PChar(MCI_DEVTYPE_AUDIO_AMPMIX);
  Result:=mciCommand( 0, MCI_OPEN,
                      MCI_WAIT or MCI_OPEN_TYPE_ID or MCI_OPEN_SHAREABLE,
                      AmpOpenParms);

  if Result then
  begin
    usDeviceID := AmpOpenParms.usDeviceID;
    GenericParms.hwndCallBack:=0;
    Result:=mciCommand(usDeviceID, MCI_ACQUIREDEVICE, MCI_EXCLUSIVE_INSTANCE,
                       GenericParms);
  end;

  if Result then
  begin
    (* Set the MixSetupParms data structure to match the loaded file.
     * This is a global that is used to setup the mixer. *)
    fillchar( MixSetupParms, sizeof( MCI_MIXSETUP_PARMS ), 0 );
    with MixSetupParms do
    begin
      ulBitsPerSample := PAudioHeader^.usBitsPerSample;
      ulFormatTag := PAudioHeader^.usFormatTag;
      ulSamplesPerSec := PAudioHeader^.ulSamplesPerSec;
      ulChannels := PAudioHeader^.usChannels;
     (* Setup the mixer for playback of wave data *)
      ulFormatMode := PlayRec;
      ulDeviceType := MCI_DEVTYPE_WAVEFORM_AUDIO;
      pmixEvent    := DARTEvent;
      Result := mciCommand( usDeviceID, MCI_MIXSETUP,
                     MCI_WAIT or MCI_MIXSETUP_INIT,
                     MixSetupParms);
    end;
  end;

  if Result AND (PlayRec=MCI_Record) then
  begin
    { Set the connector to 'Microphone' }
    fillchar( ConnectorParms, sizeof( MCI_CONNECTOR_PARMS ), 0 );
    ConnectorParms.ulConnectorType := MCI_MICROPHONE_CONNECTOR;
    {ConnectorParms.ulConnectorType := MCI_LINE_IN_CONNECTOR;}
    mciCommand( usDeviceID, MCI_CONNECTOR, 
             MCI_WAIT or  MCI_ENABLE_CONNECTOR or
	     MCI_CONNECTOR_TYPE, ConnectorParms);

   (* Allow the user to hear what is being recorded
     * by turning the monitor on *)

    fillchar( AmpSetParms, sizeof( MCI_AMP_SET_PARMS ), 0 );
    AmpSetParms.ulItem := MCI_AMP_SET_MONITOR;
    mciCommand( usDeviceID, MCI_SET,
              MCI_WAIT or MCI_SET_ON or MCI_SET_ITEM, AmpSetParms);

    { Set volume to max }
    fillchar( AmpSetParms, sizeof( MCI_AMP_SET_PARMS ), 0 );
    AmpSetParms.ulAudio := MCI_SET_AUDIO_ALL;
    AmpSetParms.ulItem := 0;
    AmpSetParms.ulLevel := 100;
    mciCommand( usDeviceID, MCI_SET, 
              MCI_WAIT or MCI_SET_AUDIO or MCI_SET_VOLUME,
              AmpSetParms);

  end;
end;


(***************************************************************************
 * Name        : DoneAmpMix
 * Description : Deallocate memory and close the Amp-Mixer Device.
 * Parameters  : None
 * Return      : BOOL   - TRUE  = failure
 *                      - FALSE = success
 ***************************************************************************)

function DoneAmpMix : boolean;
var  AmpSetParms           : MCI_AMP_SET_PARMS;
begin
    { Set volume to min }
    fillchar( AmpSetParms, sizeof( MCI_AMP_SET_PARMS ), 0 );
    AmpSetParms.ulAudio := MCI_SET_AUDIO_ALL;
    AmpSetParms.ulItem := 0;
    AmpSetParms.ulLevel := 0;
    mciCommand( usDeviceID, MCI_SET, 
              MCI_WAIT or MCI_SET_AUDIO or MCI_SET_VOLUME,
              AmpSetParms);


  Result:=mciCommand( usDeviceID, MCI_BUFFER, MCI_WAIT or MCI_DEALLOCATE_MEMORY,
                  BufferParms);
end;


function DeInitAmpMix : boolean;
begin
  Result:=mciCommand( usDeviceID, MCI_MIXSETUP, MCI_WAIT or MCI_MIXSETUP_DEINIT,
                 MixSetupParms);
end;


(****************************************************************************
 * Name        : StartRecord
 * Description : kick off the Amp-Mixer device.
 ***************************************************************************)


procedure StartRecord;
begin
  if ulNumBuffers >1 then
  begin
    ulCurrentBuf := 1;
    { Write two buffers to kick off the amp mixer. }
    MixSetupParms.pmixRead(MixSetupParms.ulMixHandle, @MixBuffers, 2);
  end
  else
  begin
    ulCurrentBuf := 0;
    MixBuffers[0].ulFlags := MIX_BUFFER_EOS;
    MixSetupParms.pmixRead( MixSetupParms.ulMixHandle,
                            @MixBuffers, 1);
  end;
  StopSound:=false;
  StopRecord:=false;
end;

(****************************************************************************
 * Name        : StartPlayBack
 * Description : kick off the Amp-Mixer device.
 ***************************************************************************)

Procedure StartPlayBack;
var
  ulIndex       : ULONG;                (* Device buffer index           *)
  ulCount       : ULONG;                (* Number of posts               *)
begin
  if ulNumBuffers > 1 then
  begin
    ulCurrentBuf := 1;
    { Write two buffers to kick off the amp mixer. }
    MixSetupParms.pmixWrite( MixSetupParms.ulMixHandle, @MixBuffers, 2);
  end else begin
    ulCurrentBuf := 0;
    { Write one buffer. }
    MixSetupParms.pmixWrite( MixSetupParms.ulMixHandle, @MixBuffers, 1);
  end;
  StopSound:=false;
  StopPlay:=false;
end;


Function SetDART(PlayRec : Ulong; GetBuf, PutBuf : BufProc;
                  Size : longint) : Boolean;
var
  mmioINFO              : OS2MM.MMIOINFO;
  lBytesRead            : LONG;
  ulBufferOffset        : LONG;
  rc, ulIndex           : ULONG;


begin
  Result:=false;

  MixSetupParms.ulBufferSize:=DARTBufSize;
  MixSetupParms.ulNumBuffers:=DARTNumBufs;

  ulBuffersToGo := Size DIV MixSetupParms.ulBufferSize;
  if ulBuffersToGo*MixSetupParms.ulBufferSize<Size then inc(ulBuffersToGo);

  (* Set up the BufferParms data structure and allocate
   * device buffers from the Amp-Mixer *)

  if ulBuffersToGo>MixSetupParms.ulNumBuffers
    then ulNumBuffers:=MixSetupParms.ulNumBuffers
    else ulNumBuffers:=ulBuffersToGo;

  BufferParms.ulNumBuffers := ulNumBuffers;
  BufferParms.ulBufferSize := MixSetupParms.ulBufferSize;
  BufferParms.pBufList := @MixBuffers;

  if not mciCommand( usDeviceID, MCI_BUFFER, MCI_WAIT or MCI_ALLOCATE_MEMORY,
                     BufferParms) then exit;

  GetBuffer:=GetBuf;
  PutBuffer:=PutBuf;
  for ulIndex := 0 to ulNumBuffers-1 do
  begin
    MixBuffers[ulIndex].ulBufferLength := BufferParms.ulBufferSize;
    if PlayRec = MCI_Play then GetBuffer(ulIndex);
  end;
  Result := true;
end;


begin
  MciError:=DefaultMCIError;
end.
