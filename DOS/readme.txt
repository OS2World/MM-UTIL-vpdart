The "Mustune.ini" file needs to be in the same folder or directory as
Mustune.  It controls many of the functions and parameters of the
program.  Here is a description of the items represented:

Calibrate - If "Yes" is entered, the soundcard will be automatically
 calibrated.  If tests with a tuning fork or other reliable device shows
 this to be inaccurate change to "No" and enter a manual correction lower
 down in the .ini file.

Mousetimer - just for beauty and may be useful for timing - will show
 ticking digital clock instead of mouse pointer. As I found may not work
 on some computers. 

Samplerate - sets sample rate of the sound card in Hertz. For analysing
 higher pitches it may be better to set higher values for example 22000,
 for lower 8000 is good enough. modulated pitch and stretching - for
 constructing temperaments different from standard. 

UserScale - Different temperaments can be used by removing the semicolon
 to the left of the series of numbers representing a particular temperament.
 There should only be one missing semicolon so be sure to put one to the
 left of the last one used before changing to another one. The pitches
 are represented by percent (cent) variation from equal temperament.

StandardPitch - This is the base upon which all pitch readings are based.
 Modern pitch is 440, Renaissance pitch is 460-466, Classical pitch is 430,
 Baroque or old pitch is 410-415, and French pitch is 390-392.

ManualCorrection - Correction in positive or negative cents to be used when
 "calibrate" = "no" to correct for a sound card which cannot be accurately
 automatically calibrated.

Smoothing - As described in the .ini file, this is to slow down the tuning
  meter.

LowerFreq - The lowest frequency one needs to measure.

UpperFreq - The highest frequency one needs to measure.

GrayScale - "Yes" for monochrome or grayscale displays, "No" for color.

RECORDING FUNCTION: (registered version only)

To record, press the button for note, spectrum, or oscilloscope then press
 record (the arrow button on the far left).   When you are done hit the
 ring (circular) button in the middle and change the name from noname.
 if you wish.  Hit enter and it will be saved to your Mustune folder.
 The extension .ptc, .spc, or .osc will be added to designate that it is
 a "pitch", "spectrum", or "oscilloscope" recording.   In this file all
 results are saved with precise timing and complete information.  You can
 view the results with any text editor including Notepad.  A graphing
 program will give you a picture of the results. The oscilloscope function
 is useful for checking to see if the sound is  recorded correctly without
 overflow (too much amplitude or volume). From this picture you may also
 visually estimate fundamental tone as the inverted period of the waveform.
 One can review all these saved files by starting the program from the DOS
 prompt using appropriate filename as a parameter in command line. For
 example:
	mustune noname.spc
	mustune noname.ptc 
	mustune noname.osc 
To restore the displays correctly the program must be run with the same
 mustune.ini file as when the displays were saved. 

The format of the spectrum file (.spc) to adds data in dB (The loudest peak
is 0dB) 

The highest notes are displayed on the stave using octave shift sign. 

About temperaments

First we take StandardPitch from ini-file that is the frequency of A4 in
Herz (default is 440.0) and construct equal temperament scale using simple
formula f=StandardPitch * 2^(d/12). Here d - is distance in semitones,
negative for lower notes. For example for the middle octave we obtain:
...
G  = 440.00*2^(-2/12)=392.00
G# = 440.00*2^(-1/12)=415.30
A  = 440.00
A# = 440.00*2^(1/12)=466.16
B  = 440.00*2^(2/12)=493.88
...
 
Now we take user defined (or predefined) temperament and apply it to our
scale. UserScale is 12 values showing the shift in cents that should be
applied to every note in octave. Cent is 1/100 of semitone so the shift
should be calculated using the following formula fnew=fold*2^(c/1200).

For example we want to apply Pythagorean scale:

-6,8,-2,-12,2,-8,6,-4,10,0,-10,4

Now we need to choose to what starting note this modulation should be
applied that is defined by ModulatedPitch. All predefined temperaments
are calculated for ModulatedPitch C. Now let we want to apply this
temperament to D (ModulatedPitch = D). It may be donein the following
way (by cyclically shifting the table for UserScale)

C   C#  D   D#  E   F   F#  G   G#  A   A#  B
        -6  8   -2  -12 2   -8  6   -4  10  0
-10 4

so the new table will be:
-10,4,-6,8,-2,-12,2,-8,6,-4,10,0

However there is a problem in this new table: if applied it will shift
our StandardPitch on -4 cents. It is not what we want. To avoid this
undesirable shift we define ZeroPitch. Usually and by default it is the
same note as standard pitch A.

To preserve our ZeroPitch umodulated we must add +4 to every value in our
table to obtain:

-6,8,-2,12,2,-8,6,-4,10,0,14,4

Now we calculate the new scale
...
G  = 392.00*2^(-4/1200)= 391.10
G# = 415.30*2^(10/1200)= 417.71
A  = 440.00
A# = 466.16*2^(14/1200)= 469.96
B  = 493.88*2^(4/1200) = 495.02
...

We may also apply Stretching to our new temperament for more pleasant sound.
Below is three tables for equal temperament and different levels of stretching.

Stretching = 0 (default, no stretching)

 ³ C     C#    D     D#    E     F     F#    G     G#    A     A#    B    
ÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
0³ 16.35 17.32 18.35 19.45 20.60 21.83 23.12 24.50 25.96 27.50 29.14 30.87
1³ 32.70 34.65 36.71 38.89 41.20 43.65 46.25 49.00 51.91 55.00 58.27 61.74
2³ 65.41 69.30 73.42 77.78 82.41 87.31 92.50 98.00 103.8 110.0 116.5 123.5
3³ 130.8 138.6 146.8 155.6 164.8 174.6 185.0 196.0 207.7 220.0 233.1 246.9
4³ 261.6 277.2 293.7 311.1 329.6 349.2 370.0 392.0 415.3 440.0 466.2 493.9
5³ 523.3 554.4 587.3 622.3 659.3 698.5 740.0 784.0 830.6 880.0 932.3 987.8
6³  1047  1109  1175  1245  1319  1397  1480  1568  1661  1760  1865  1976
7³  2093  2217  2349  2489  2637  2794  2960  3136  3322  3520  3729  3951
8³  4186  4435  4699  4978  5274  5588  5920  6272  6645  7040  7459  7902


Stretching = 1

 ³ C     C#    D     D#    E     F     F#    G     G#    A     A#    B    
ÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
0³ 16.29 17.26 18.29 19.39 20.55 21.77 23.07 24.45 25.91 27.46 29.10 30.83
1³ 32.67 34.62 36.68 38.87 41.18 43.63 46.23 48.99 51.90 54.99 58.26 61.73
2³ 65.41 69.30 73.42 77.79 82.41 87.31 92.51 98.01 103.8 110.0 116.6 123.5
3³ 130.8 138.6 146.8 155.6 164.8 174.6 185.0 196.0 207.6 220.0 233.1 246.9
4³ 261.6 277.2 293.6 311.1 329.6 349.2 370.0 392.0 415.3 440.0 466.2 493.9
5³ 523.3 554.4 587.4 622.4 659.4 698.7 740.3 784.4 831.1 880.7 933.2 988.8
6³  1048  1110  1176  1247  1321  1400  1484  1572  1666  1766  1872  1984
7³  2102  2228  2362  2503  2654  2813  2982  3161  3351  3553  3767  3994
8³  4235  4490  4762  5050  5355  5680  6024  6390  6778  7190  7628  8093

Stretching = 2

 ³ C     C#    D     D#    E     F     F#    G     G#    A     A#    B    
ÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
0³ 16.22 17.20 18.23 19.33 20.49 21.72 23.02 24.40 25.86 27.41 29.05 30.79
1³ 32.63 34.58 36.64 38.83 41.15 43.60 46.20 48.96 51.88 54.97 58.24 61.71
2³ 65.39 69.28 73.41 77.78 82.40 87.31 92.50 98.00 103.8 110.0 116.5 123.5
3³ 130.8 138.6 146.8 155.6 164.8 174.6 185.0 196.0 207.6 220.0 233.1 246.9
4³ 261.6 277.2 293.6 311.1 329.6 349.2 370.0 392.0 415.3 440.1 466.3 494.0
5³ 523.4 554.6 587.7 622.7 659.8 699.1 740.8 785.0 831.9 881.6 934.2 990.0
6³  1049  1112  1179  1249  1324  1403  1487  1577  1671  1772  1878  1991
7³  2111  2239  2374  2517  2669  2831  3002  3185  3378  3583  3802  4033
8³  4280  4541  4819  5115  5429  5763  6119  6497  6899  7326  7782  8266


Stretching = 3

 ³ C     C#    D     D#    E     F     F#    G     G#    A     A#    B    
ÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
0³ 16.15 17.13 18.17 19.26 20.43 21.66 22.96 24.34 25.80 27.35 28.99 30.73
1³ 32.57 34.53 36.59 38.78 41.10 43.55 46.16 48.91 51.83 54.92 58.20 61.67
2³ 65.35 69.24 73.37 77.74 82.37 87.27 92.46 97.97 103.8 110.0 116.5 123.5
3³ 130.8 138.6 146.8 155.6 164.8 174.6 185.0 196.0 207.7 220.0 233.1 247.0
4³ 261.7 277.2 293.7 311.2 329.7 349.4 370.2 392.2 415.6 440.3 466.5 494.3
5³ 523.8 555.0 588.1 623.2 660.4 699.9 741.7 786.0 833.0 882.8 935.6 991.7
6³  1051  1114  1181  1252  1327  1407  1492  1581  1677  1778  1886  2000
7³  2121  2249  2386  2531  2685  2849  3023  3209  3405  3615  3837  4074
8³  4326  4594  4879  5183  5507  5852  6219  6611  7028  7474  7949  8456


