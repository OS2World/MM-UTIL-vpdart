const
{DART}
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
  usDeviceID		: USHORT;		(* Amp Mixer device id	   *)
  ulBufferCount 	: ULONG;		(* Current file buffer	   *)
  ulNumBuffers		: ULONG;		(* Number of file buffers  *)
  MixBuffers		: Array[0..MAX_BUFFERS-1] of MCI_MIX_BUFFER;	
						(* Device buffers	   *)
  MixSetupParms 	: MCI_MIXSETUP_PARMS;	(* Mixer parameters	   *)
  BufferParms		: MCI_BUFFER_PARMS;	(* Device buffer parms	   *)
  GenericParms		: MCI_GENERIC_PARMS;

(***************************************************************************
 * Name        : MyEvent
 *
 * Description : The address to this procedure is passed to the mixer
 *		 device in the MIX_SETUP_PARMS structure. The mixer
 *		 device then calls this procedure when it has expended
 *		 a buffer.
 *
 *		 NOTE: This is a high priority thread. Too much code here
 *		       will bog the system down.
 *
 * Parameters  : ulStatus - Detailed error message
 *		 pBuffer  - Pointer to expended buffer
 *		 ulFlags  - Indicates the type of event
 *
 *
 * Return      : BOOL	- TRUE	= failure
 *			- FALSE = success
 *
 ***************************************************************************)

Function MyEvent ( ulStatus : ULONG;
		   pBuffer  : PMCI_MIX_BUFFER;
		   ulFlags  : ULONG ) : LONG; CDecl;

begin
  case ulFlags of
    MIX_STREAM_ERROR or MIX_READ_COMPLETE ,  (* error occur in device *)
    MIX_STREAM_ERROR or MIX_WRITE_COMPLETE:  (* error occur in device *)
      if ulStatus = ERROR_DEVICE_UNDERRUN then begin
	  (* handle ERROR_DEVICE_UNDERRUN or OVERRUN here
	   *)
      end;

    MIX_READ_COMPLETE : 		     (* for recording *)
      if  ulBufferCount >= ulNumBuffers then begin
	 mciSendCommand( usDeviceID,
			 MCI_STOP,
			 MCI_WAIT,
			 GenericParms,
			 0 );
        {ResetPlayBack;}
     end else begin
	MixSetupParms.pmixRead( MixSetupParms.ulMixHandle,
				pBuffer, 1 );
	inc(ulBufferCount);
    end;

    MIX_WRITE_COMPLETE: 	  (* for playback  *)
       if( ulBufferCount >= ulNumBuffers ) then begin
	 mciSendCommand( usDeviceID,
			 MCI_STOP,
			 MCI_WAIT,
			 GenericParms,
			 0 );
         StopPlay:=true;
       end else begin
	 MixSetupParms.pmixWrite( MixSetupParms.ulMixHandle,
				   @MixBuffers[ulBufferCount], 1 );
	 inc(ulBufferCount);
       end;
  end; 
  MyEvent:=LONG( TRUE );
end; (* end MyEvent *)


(***************************************************************************
 * Name        : MciError
 * Description : Display a message box with the string corresponding to
 *		 the passed mci error code.
 * Parameters  : ulError = mci error code
 * Return      : None
 ***************************************************************************)

Procedure MciError( ulError : ULONG );
var
  szBuffer	: Array[ 0..STRING_LENGTH-1 ] OF Char;
  rc		: ULONG;
begin
  rc := mciGetErrorString( ulError, szBuffer, STRING_LENGTH );
  Writeln(szBuffer);
end;


function mciCommand(usDeviceID: uShort; usMessage: uShort; ulParam1: uLong;
	            var Param2) : boolean;
var
  rc		: ULONG;
begin
  rc:=mciSendCommand(usDeviceID, usMessage, ulParam1, Param2, 0);
  MciCommand := (rc=MCIERR_SUCCESS);
  if rc <> MCIERR_SUCCESS then MciError( rc );
end;


function AmpMixOpen : boolean;
var
  AmpOpenParms : MCI_AMP_OPEN_PARMS;
begin
  (* open the mixer device *)
  fillchar( AmpOpenParms, sizeof( MCI_AMP_OPEN_PARMS ), 0 );
  AmpOpenParms.usDeviceID := (* USHORT *) 0;
  AmpOpenParms.pszDeviceType := PChar(MCI_DEVTYPE_AUDIO_AMPMIX);

  AmpMixOpen:=mciCommand( 0, MCI_OPEN,
                MCI_WAIT or MCI_OPEN_TYPE_ID or MCI_OPEN_SHAREABLE,
                AmpOpenParms);
  usDeviceID := AmpOpenParms.usDeviceID;
end;


(***************************************************************************
 * Name        : Close
 * Description : Deallocate memory and close the Amp-Mixer Device.
 * Parameters  : None
 * Return      : BOOL	- TRUE	= failure
 *			- FALSE = success
 ***************************************************************************)

function AmpMixClose : boolean;
begin
  AmpMixClose:=false;
  if mciCommand( usDeviceID, MCI_BUFFER, MCI_WAIT or MCI_DEALLOCATE_MEMORY,
                  BufferParms) then exit;
  AmpMixClose:=mciCommand( usDeviceID, MCI_CLOSE, MCI_WAIT, GenericParms);
end;


(***************************************************************************
 * Name        : ResetRecord
 *
 * Description : Using the information stored in the MixSetupParms data
 *		 structure, the Amp-Mixer device is opened for recording.
 *		 Enough device buffers are allocated to fill preallocated
 *		 application buffers. Recording is then started and will
 *		 continue until all of the device buffers are full ( or
 *		 until the user selects the STOP button.
 *
 *
 * Parameters  : None
 *
 * Return      : BOOL	- TRUE	= failure
 *			- FALSE = success
 *
 ***************************************************************************)

Function ResetRecord : Boolean;
var
  ConnectorParms	: MCI_CONNECTOR_PARMS;
  AmpSetParms		: MCI_AMP_SET_PARMS;

begin
  ResetRecord := false;
  { Deinitialize the Amp-Mixer to reset for record mode }
  if mciCommand( usDeviceID, MCI_MIXSETUP, MCI_WAIT or MCI_MIXSETUP_DEINIT,
 		 MixSetupParms) then exit;

  (* Setup the mixer for record
   * Note: MixSetupParms is a global data structure. Most of this
   *	   structure must be set before this point. The LoadFile
   *	   procedure is the first place that this is done.
   *)
  MixSetupParms.ulFormatMode := MCI_RECORD;

  if mciCommand( usDeviceID, MCI_MIXSETUP, MCI_WAIT or MCI_MIXSETUP_INIT,
 		MixSetupParms) then exit;

  { Zero out the device buffers. }
  for ulBufferCount := 0 to ulNumBuffers-1 do
    fillchar( MixBuffers[ulBufferCount].pBuffer^,
	      MixBuffers[ulBufferCount].ulBufferLength, 0 );

 { Set the connector to 'line in' }
 fillchar( ConnectorParms, sizeof( MCI_CONNECTOR_PARMS ), 0 );
 ConnectorParms.ulConnectorType := MCI_LINE_IN_CONNECTOR;
  mciSendCommand( usDeviceID, MCI_CONNECTOR, 
                MCI_WAIT or MCI_ENABLE_CONNECTOR or MCI_CONNECTOR_TYPE,
 	        ConnectorParms,0);

 (* Allow the user to hear what is being recorded
  * by turning the monitor on *)

 fillchar( AmpSetParms, sizeof( MCI_AMP_SET_PARMS ), 0 );
  AmpSetParms.ulItem := MCI_AMP_SET_MONITOR;
  mciSendCommand( usDeviceID, MCI_SET, MCI_WAIT or MCI_SET_ON or MCI_SET_ITEM,
  	     AmpSetParms,0);

  (* Reset the buffer counter   *)
  ulBufferCount := 0;

  {Kick off the mixer.}
  if ulNumBuffers < 2 then begin

  (* If there is only one buffer to read  then tell the mixer that
   * this is the end of the stream. If this flag is not set then
   * the mixer would not start with less than two buffers.
   *)
    MixBuffers[0].ulFlags := MIX_BUFFER_EOS;
    MixSetupParms.pmixRead( MixSetupParms.ulMixHandle,
			    @MixBuffers[ulBufferCount],
			    1 );
  end else
    MixSetupParms.pmixRead( MixSetupParms.ulMixHandle, @MixBuffers,
			    ulNumBuffers );
  ResetRecord := true;
end;




(****************************************************************************
 * Name        : ResetPlayBack
 *
 * Description : Reinit the Amp-Mix device for play-back, allocate  device
 *		 buffers, copy audio data to device buffers and kick off
 *		 the Amp-Mixer device.
 *
 * Parameters  : None
 *
 * Return      : None
 *
 ***************************************************************************)
Function ResetPlayBack : Boolean;
var
  ConnectorParms	: MCI_CONNECTOR_PARMS;
  AmpSetParms		: MCI_AMP_SET_PARMS;
  rc			: ULONG;

begin
  { Deinitialize the Amp-Mixer to reset for record mode }
  ResetPlayBack:=false; 
  if mciCommand( usDeviceID, MCI_MIXSETUP,
      	      MCI_WAIT or MCI_MIXSETUP_DEINIT, MixSetupParms) then exit;

  (* Setup the mixer for play-back
   * Note: MixSetupParms is a global data structure. Most of this
   *	   structure must be set before this point. The LoadFile
   *	   procedure is the first place that this is done.
   *)
  MixSetupParms.ulFormatMode := MCI_PLAY;
  if mciCommand( usDeviceID, MCI_MIXSETUP, MCI_WAIT or MCI_MIXSETUP_INIT, 
                 MixSetupParms) then exit;
  ResetPlayBack := true;
end;



(****************************************************************************
 * Name        : StartPlayBack
 * Description : Copy all of the application buffers to device buffers
 *		 and kick off the Amp-Mixer device.
 ***************************************************************************)

Procedure StartPlayBack;
var
  ulIndex	: ULONG;		(* Device buffer index		 *)
  ulCount	: ULONG;		(* Number of posts		 *)
begin
  if ulNumBuffers > 1 then begin
    ulBufferCount := 2;
    { Write two buffers to kick off the amp mixer. }
    MixSetupParms.pmixWrite( MixSetupParms.ulMixHandle, @MixBuffers, 2 );
  end else begin
    ulBufferCount := 1;
    { Write one buffer. }
    MixSetupParms.pmixWrite( MixSetupParms.ulMixHandle, @MixBuffers, 1 );
  end;
end;

