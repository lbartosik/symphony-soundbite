;**************************************************************************
;***
;***	Copyright 2007, Freescale, Inc.  All rights reserved.
;***
;**************************************************************************
;***
;***	Memory control file for basic SoundBite applications
;***
;**************************************************************************


base	x:0,y:0,p:$100	; important to set P base at $100 to prevent 
						; application code from being placed into vector table
						; when linker links everything

RESERVE		p:$000000..$0000FF			; reserve int vecs
RESERVE     p:$003000..$FFFFFF

RESERVE     x:$003000..$00C000
RESERVE     x:$010000..$FFFFFF

RESERVE     y:$002000..$00C000
RESERVE     y:$016000..$FFFFFF

SECTION 	main
SECTION 	codecs
SECTION     esai
SECTION     serial

; the linker does not like a control file that 
; ends at the last character of the last file name with no newline character...
