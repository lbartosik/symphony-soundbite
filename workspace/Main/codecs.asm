	page		132,60	
	section		codecs
	  
	nolist
	include "../../dsp_crt0/dsp_regs.equ"	
	include "../codecs.equ"		
	list 

;**************************************************************************
; Global symbols
;**************************************************************************

	GLOBAL configure_AK4584,initialize_AK4584

;**************************************************************************
; Data in Y space
;**************************************************************************
 
;**************************************************************************
; Code in P space
;**************************************************************************
	
	org p: 

DELAY
	dor #DELAY_AK4584,delay_loop
		nop
		nop
		nop
delay_loop
	nop
	rts

;**************************************************************************
; Subroutine to setup GPIO pins for bit bang communication with AK4584
;**************************************************************************
initialize_AK4584
	bset #CSN,y:AK4584_dat	;set data register for outputs
	bset #CDTI,y:AK4584_dat
	bset #CCLK,y:AK4584_dat

	bset #CSN,y:AK4584_dir	;set data dir register
	bset #CDTI,y:AK4584_dir
	bset #CCLK,y:AK4584_dir
	bclr #CDTO,y:AK4584_dir
	
	bclr #CSN,y:AK4584_ctl	;set control register
	bclr #CDTI,y:AK4584_ctl
	bclr #CCLK,y:AK4584_ctl
	bset #CDTO,y:AK4584_ctl
	
	rts

;**************************************************************************
; Subroutine to transmit a control word to AK4584
;
; expects AK4584 register addr in x0, data byte to send in x1 (in upper 8 bits)
;**************************************************************************
TX_AK4584
	clr a
	or	#ak4584_write,a			; OR upper bits of tx word
	or	x0,a					; OR address with tx word
	lsl	#8,a					; shift 8 bits left by 8
	or	x1,a					; OR data with tx word
	
	bclr #CSN,y:AK4584_dat		; assert chip select of ak4584
	bsr DELAY
	
	dor #16,tx_loop				; loop over 16 bits
		bclr #CCLK,y:AK4584_dat	; clock low
		bsr DELAY
		
; figure out what bit to output, there is probably a more efficient way to do this...
		move a,b				; move tx word to b
		and #$8000,b			; select topmost bit
		jeq	txzero				; figure out what bit value to send
		bset #CDTI,y:AK4584_dat	; send a 1
		jmp	txtoggle_clock		
txzero	
		bclr #CDTI,y:AK4584_dat	; send a 0	
		
txtoggle_clock	
		bsr DELAY
		
		bset #CCLK,y:AK4584_dat	; clock high
		bsr DELAY
		and #$ffff,a			; clear upper 8 bits to avoid sign extension bit probs
		lsl #1,a				; shift tx word left by one bit (next bit to send)
		nop
		nop
tx_loop
	
	bset #CSN,y:AK4584_dat		; deassert chip select of ak4584
	bsr DELAY
	
	rts

configure_AK4584
	move #>0,x0					; AK4584 Power Down Control
	move #>$0,x1				; power down all modules
	bsr TX_AK4584
	
	move #>0,x0					; AK4584 Power Down Control
	move #>$1f,x1				; power up all modules
	bsr TX_AK4584
	
	move #>1,x0					; AK4584 Reset Control
	move #>0,x1					; reset ADC and DAC
	bsr TX_AK4584
	
	move #>1,x0					; AK4584 Reset Control
	move #>3,x1					; set DAC and ADC for normal operation
	bsr TX_AK4584
	 
	move #>6,x0					; AK4584 output attenuator left
	move #>$ff,x1				; set output attentuator left ($FF default, no attenuation)
	bsr TX_AK4584
	
	move #>7,x0					; AK4584 output attenuator right
	move #>$ff,x1				; set output attentuator right ($FF default, no attenuation)
	bsr TX_AK4584
	
	move #>9,x0					; AK4584 Clock Mode Control
	move #>$2a,x1				; Sampling rate:  4a = 96 kHz, 2a = 48 kHz, 1a = 64 kHz
	bsr TX_AK4584
	
	move #>2,x0					; AK4584 Clock and format 
	move #>$c,x1				; set I2S mode
	bsr TX_AK4584
 
	move #>8,x0					; AK4584 In/Out Source Control
	move #>$11,x1			    ; set inputs/outputs of AK4584 per y0 
	bsr TX_AK4584				; as it was passed into this routine

	rts
	
	endsec   
	