Below are the sources for using DART and working with WAV files in OS/2.

WAVCONV      - converts WAV-file, encoded with MSADPCM, ALAW or ULAW into
	       PCM
WAVPLAY      - plays MSADPCM, ULAW, ALAW encoded or PCM-files using DART
WAVREC       - records WAV PCM file through microphone using DART
PLAYMCI      - plays WAV-file using MCI interface
	      (in WARP4 - ADPCM, ULAW, ALAW do not work, bug in WARP4?
               though all filters and codecs are present)
WAVINFO      - shows WAV-file format
<PM>         - DART example from WARP TOOLKIT converted to VP. 
               Also a good example of simple PM program.

P.S. WAVCONV, PLAYMCI, WAVINFO, WAVUNIT may be compiled as console
applications for WINDOWS-95/98 using DELPHI-3 (dcc32 -cc *.pas).
Don't have VP 2.0 to try it. I would be happy if someone could
add replacement of DART.PAS for WINDOWS (Direct Sound or WAVEIN, WAVEOUT)
to compile  WAVPLAY and WAVREC.

P.P.S These sources are the results of efforts to port my DOS program for
musical pitch recognition in OS/2. If you want to support these efforts
purchasing DOS version (it works nicely under OS/2 and WINDOWS, too), 
please contact

Prescott Workshop
14 Grant Road
Hanover, NH 03755 USA

Tel :(603) 643-6442
Fax.:(603) 643-5219
E-mail: recorders@aol.com

OS/2 version unlike WINDOWS if I'll manage to finish them will be free!!!

 	  Michael L. Gorodetsky, gorm@mol.phys.msu.su