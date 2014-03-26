Program DAudio;
{$PMTYPE PM }{$S-}{$R *.RES}{&CDecl+}
uses Use32,Os2Def,Os2PMApi,os2mm;


const
  ID_DIALOG      = 100;
  ID_PLAY        = 101;
  ID_RECORD      = 102;
  ID_STOP        = 103;
  ID_ICON        = 104;
  STRING_LENGTH  = 128;
  MAX_BUFFERS    = 256;
  DEFAULT_FILE = 'daudio.wav';

var
  hwndFrame		: HWND; 		(* Dialog fram window id   *)

{$I DART.INC}

(***************************************************************************
 * Name        : LoadFile
 *
 * Description : Allocate application buffers for audio file and load
 *		 audio file. These buffers will be copied to device
 *		 buffers by another thread.
 *
 *		 Before this procedure loads the audio file, the global
 *		 MixSetupParms data structure is loaded with information
 *		 from the audio files header.
 *
 *
 * Parameters  : CHAR szFilename[]     - Name of wave file to open
 *
 * Return      : BOOL	- TRUE	= failure
 *			- FALSE = success
 *
 ***************************************************************************)

Function LoadFile( szFileName:PChar ):Boolean;
var
  mmioINFO		: OS2MM.MMIOINFO;
  mmAudioHeader 	: OS2MM.MMAUDIOHEADER;
  hmmio 		: OS2MM.HMMIO;
  lBytesRead		: LONG;
  ulBufferOffset	: LONG;
  AmpOpenParms		: MCI_AMP_OPEN_PARMS;
  rc, ulIndex		: ULONG;
begin

  (* open the mixer device *)
  fillchar( AmpOpenParms, sizeof( MCI_AMP_OPEN_PARMS ), 0 );
  AmpOpenParms.usDeviceID := (* USHORT *) 0;
  AmpOpenParms.pszDeviceType := PChar(MCI_DEVTYPE_AUDIO_AMPMIX);

  if not mciCommand( 0, MCI_OPEN, 
			MCI_WAIT or MCI_OPEN_TYPE_ID or MCI_OPEN_SHAREABLE,
			AmpOpenParms) then
  begin
    LoadFile := false;
    exit;
  end;

  usDeviceID := AmpOpenParms.usDeviceID;

  (* Open the audio file. *)

  fillchar( mmioInfo, sizeof( MMIOINFO ), 0 );
  mmioInfo.fccIOProc := mmioFOURCC( 'W', 'A', 'V', 'E' );
  hmmio := mmioOpen( szFileName, @mmioInfo, MMIO_READ or MMIO_DENYNONE );

  if hmmio=0 then begin

    WinMessageBox( HWND_DESKTOP,
		   HWND_DESKTOP,
		   'Unable to open wave file',
		   'MMIO Error',
		   0,
		   MB_OK or MB_ERROR or MB_MOVEABLE);

    LoadFile := false;
    exit;
  end;

  (* Get the audio file header. *)
  mmioGetHeader( hmmio, @mmAudioHeader, sizeof( MMAUDIOHEADER ),
		 @lBytesRead, 0, 0);

  (* Set the MixSetupParms data structure to match the loaded file.
   * This is a global that is used to setup the mixer. *)

  fillchar( MixSetupParms, sizeof( MCI_MIXSETUP_PARMS ), 0 );

  MixSetupParms.ulBitsPerSample :=
	mmAudioHeader.mmXWAVHeader.WAVEHeader.usBitsPerSample;

  MixSetupParms.ulFormatTag :=
	mmAudioHeader.mmXWAVHeader.WAVEHeader.usFormatTag;

  MixSetupParms.ulSamplesPerSec :=
	mmAudioHeader.mmXWAVHeader.WAVEHeader.ulSamplesPerSec;

  MixSetupParms.ulChannels :=
	mmAudioHeader.mmXWAVHeader.WAVEHeader.usChannels;

  (* Setup the mixer for playback of wave data *)
  MixSetupParms.ulFormatMode := MCI_PLAY;
  MixSetupParms.ulDeviceType := MCI_DEVTYPE_WAVEFORM_AUDIO;
  MixSetupParms.pmixEvent    := MyEvent;

  if not mciCommand( usDeviceID, MCI_MIXSETUP,
		     MCI_WAIT or MCI_MIXSETUP_INIT, MixSetupParms) then
  begin
    LoadFile := false;
    exit;
  end;

  (* Use the suggested buffer size provide by the mixer device
   * and the size of the audio file to calculate the required
   * number of Amp-Mixer buffers.
   * Note: The result is rounded up 1 to make sure we get the
   *	   tail end of the file.
   *)
  ulNumBuffers :=
	mmAudioHeader.mmXWAVHeader.XWAVHeaderInfo.ulAudioLengthInBytes
	DIV MixSetupParms.ulBufferSize + 1;


  (* Set up the BufferParms data structure and allocate
   * device buffers from the Amp-Mixer
   *)
  BufferParms.ulNumBuffers := ulNumBuffers;
  BufferParms.ulBufferSize := MixSetupParms.ulBufferSize;
  BufferParms.pBufList := @MixBuffers;

  if not mciCommand( usDeviceID,
			MCI_BUFFER,
			MCI_WAIT or MCI_ALLOCATE_MEMORY,
			BufferParms) then
  begin
    LoadFile := false;
    exit;
  end;

  (* Fill all device buffers with data from the audio file.
   *)
  for ulIndex := 0 to ulNumBuffers-1 do begin
    fillchar( MixBuffers[ ulIndex ].pBuffer^, BufferParms.ulBufferSize, 0 );
    MixBuffers[ ulIndex ].ulBufferLength := BufferParms.ulBufferSize;

    rc := mmioRead ( hmmio,
		     MixBuffers[ ulIndex ].pBuffer,
		     MixBuffers[ ulIndex ].ulBufferLength );

  end;

  (* Set the "end-of-stream" flag
   *)
  MixBuffers[ulNumBuffers - 1].ulFlags := MIX_BUFFER_EOS;

  mmioClose( hmmio, 0 );

  LoadFile := true;
end;


(***************************************************************************
 * Name        : MainDialogProc
 *
 * Description : This function controls the main dialog box.  It will handle
 *		 received messages such as pushbutton notifications, and
 *		 entry field messages.
 *
 *
 ***************************************************************************)
const
  hwndPlayButton	: OS2Def.HWND = NULLHANDLE;
  hwndRecordButton	: OS2Def.HWND = NULLHANDLE;
  hwndStopButton	: OS2Def.HWND = NULLHANDLE;
  fPassedDevice 	: BOOLEAN = TRUE;
  fRecording		: BOOLEAN = FALSE;



Function MainDialogProc( hwnd : HWND;
			 msg  : ULONG;
			 mp1  : MPARAM;
			 mp2  : MPARAM ) : MRESULT;
var
  GenericParms		: MCI_GENERIC_PARMS;
  ulIndex,rc		: ULONG;
begin
  case msg of
    WM_INITDLG: begin
      (* Get the handles for the PLAY and RECORD buttons
       *)
      hwndPlayButton := WinWindowFromID( hwnd, ID_PLAY );
      hwndRecordButton := WinWindowFromID( hwnd, ID_RECORD );
      hwndStopButton := WinWindowFromID( hwnd, ID_STOP );

      (* Disable the stop button
       *)
      WinEnableWindow( hwndStopButton, FALSE );

      (* Load the audio file and setup for playback.
       *)
      
      if not LoadFile( DEFAULT_FILE ) then WinPostMsg( hwnd, WM_QUIT, 0, 0 );
    end;
    MM_MCIPASSDEVICE: begin

      (* Check if we are gaining or passing use of the amp-mixer device
       *)
      if SHORT1FROMMP( mp2 ) = MCI_GAINING_USE then
	 fPassedDevice := FALSE
      else
	 fPassedDevice := TRUE;

    end;

    WM_ACTIVATE: begin

      (* Check if this window is the active window and if we have passed
       * use of the Amp-Mixer device. If yes, then send MCI_ACQUIREDEVICE
       * message. *)
      if Boolean( mp1 ) and fPassedDevice then begin

	 GenericParms.hwndCallback := hwnd;

	 mciCommand( usDeviceID, MCI_ACQUIREDEVICE,
		     MCI_NOTIFY or MCI_ACQUIRE_QUEUE,GenericParms);
      end;
    end;

    WM_COMMAND: case SHORT1FROMMP ( mp1 ) of

      ID_PLAY: begin

	 (* Disable the play and record buttons
	  * Enable the stop button.
	  *)
	 WinEnableWindow( hwndPlayButton, FALSE );
	 WinEnableWindow( hwndRecordButton, FALSE );
	 WinEnableWindow( hwndStopButton, TRUE );

	 StartPlayBack;

	 MainDialogProc := MRESULT( FALSE );
	 exit;
      end;

      ID_RECORD: begin
	 (* The new recording will overwrite the file that was loaded
	  * at the start of the program. If the user presses the PLAY
	  * button, the newly recorded file will be played.
	  *)
	 if ResetRecord then begin
	    fRecording := TRUE;       
	    (* Disable the play and record buttons
	     * Enable the stop button. *)
	    WinEnableWindow( hwndPlayButton, FALSE );
	    WinEnableWindow( hwndRecordButton, FALSE );
	    WinEnableWindow( hwndStopButton, TRUE );
	  end;
	 MainDialogProc := MRESULT( FALSE );
         exit;
      end;

      ID_STOP: begin
	 { Send message to stop the audio device }
	 mciCommand( usDeviceID, MCI_STOP, MCI_WAIT, GenericParms );

	 { If we were recording then reset for playback }
	 if fRecording then begin

	    { Reset the Amp-Mixer device for playback }
	    ResetPlayBack;
	    fRecording := FALSE;

	 end; 


	 (* Enable the play and record buttons *)
	 WinEnableWindow( hwndRecordButton, TRUE );
	 WinEnableWindow( hwndPlayButton, TRUE );
	 WinEnableWindow( hwndStopButton, FALSE );

	 MainDialogProc := MRESULT( FALSE );
	 exit;
      end;
    end; (* end switch *)

    WM_CLOSE: begin

      Close;

      WinPostMsg( hwnd, WM_QUIT, 0, 0 );
      MainDialogProc := MRESULT( FALSE );
      exit;
    end;

  end; (* end switch *)

   (* Pass messages on to the frame window
    *)
  MainDialogProc := WinDefDlgProc( hwnd, msg, mp1, mp2 );

end; (* End MainDialogProc *)


var
  rc		: ULONG;
  hab		: OS2Def.HAB;
  hmq		: OS2Def.HMQ;
  qmsg		: OS2PMAPI.QMSG;
  ulIndex	: ULONG;

begin
   hab := WinInitialize(0);
   hmq := WinCreateMsgQueue(hab,0);

   hwndFrame := WinLoadDlg( HWND_DESKTOP,
			    HWND_DESKTOP,
			    MainDialogProc,
			    NULLHANDLE,
			    ID_DIALOG,
			    NIL );

   while WinGetMsg( hab, qmsg, NULLHANDLE, 0, 0 ) do 
     WinDispatchMsg( hab, qmsg );

   WinDismissDlg( hwndFrame, ULONG( TRUE ) );
   WinDestroyMsgQueue( hmq );
   WinTerminate( hab );
end. (* end main *)


