	page		132,60	
	section		esai
	 
	nolist 
	include "../../dsp_crt0/dsp_regs.equ"	
	include "../esai.equ"		
	list 
 
;**************************************************************************
; Global symbols
;**************************************************************************
	
	GLOBAL setup_ESAI_0,setup_ESAI_1
	GLOBAL RX_OVERRUN_COUNTER,TX_UNDERRUN_COUNTER
	GLOBAL TX_DATA_LEFT_CHANNEL,TX_DATA_RIGHT_CHANNEL
	GLOBAL RX_DATA_LEFT_CHANNEL,RX_DATA_RIGHT_CHANNEL
	GLOBAL PROCESS_DATA_FLAG,ENABLE_PROCESSING
	GLOBAL RX_DATA_LEFT_PTR,RX_DATA_RIGHT_PTR
	GLOBAL DMA_TEST

;**************************************************************************
; Data in Y space
;**************************************************************************
	org y:

PROCESS_DATA_FLAG dc	0
ENABLE_PROCESSING dc $FFFFFF

TX_UNDERRUN_COUNTER ds 1
RX_OVERRUN_COUNTER ds 1

TX_DATA_LEFT_CHANNEL ds 4
TX_DATA_RIGHT_CHANNEL ds 4


RX_DATA_LEFT_PTR ds 1
RX_DATA_RIGHT_PTR ds 1

RX_DATA_LEFT_CHANNEL dsm NUMBER_OF_CHANNELS*CHANNEL_BUFFER_SIZE
RX_DATA_RIGHT_CHANNEL dsm NUMBER_OF_CHANNELS*CHANNEL_BUFFER_SIZE

DMA_TEST ds 100


;**************************************************************************
; Code in P space
;**************************************************************************
	
	org p:

;**************************************************************************        
; Initialize ESAI - ESAI is only used for I2S output to all codecs
; FST/FSR and SCKT/SCKR are generated externally by AK4584
;**************************************************************************        
INIT_ESAIS_

	



;**************************************************************************        
; Initialize ESAI_1 - ESAI_1 is only used for I2S input from all codecs
; FST/FSR and SCKT/SCKR are generated externally by AK4584
;**************************************************************************        
;	movep	#$000000,y:M_PCRE		;disable ESAI_1 port;
	;movep	#$000000,y:M_PRRE
	;movep	#$0c0200,y:M_RCCR_1		;init receive clock control register
	;movep	#$000000,y:M_SAICR_1	;init ESAI_1 common control register
	;movep	#$717D0F,y:M_RCR_1		;init receive control register
	;movep	#$0003c3,y:M_PCRE		;Enable ESAI_1 port
	;movep	#$0003c3,y:M_PRRE
	;movep	#$00ffff,y:M_RSMA_1		;init receive slot mask registers
	;movep	#$00ffff,y:M_RSMB_1

	rts
  
 
;**************************************************************************
; ESAI 0 is used to transmit data to 4 codecs
;**************************************************************************	 
setup_ESAI_0                
    movep #$000000,x:PORT_C_CTRL_REG  ; Disable port C     						   		   
    movep #$000000,x:PORT_C_DIR_REG   
        
    movep #$0C0200,x:M_TCCR     ; Transmit clock control register    						
    							; Transmit frame sync signal direction, FST is an input (bit22=0)
								; Transmit clock source direction, SCKT is an input (bit21=0)
								; Negative FST polarity (bit19=1)
								; Data & FST clocked out on rising edge(bit18=1)
								; 2 words per frame (bit13:9=00001)
    
    movep #$000000,x:M_SAICR   	; M_SAICR = 0; ESAI Common Control Register 
        
    movep #$717d00,x:M_TCR      ; M_TCR = 0x717d00; ESAI Transmit Control Register    
								; TX0, TX1, TX2, TX3, TX4, TX5 disabled (bit5:0=000000)						
								; MSB shifted first (bit6=0)
								; word left-aligned (bit7=0)
								; network mode (bit9:8=01)
								; 32-bit slot length, 24-bit word length (bit14:10=11111)
								; word length frame sync (bit15=0)
								; frame sync occurs 1 clock cycle earlier (bit16=1)						
								; TIE, TEDIE, TEIE enabled (bit23:20=0111)
								; bit23 TLIE
								; bit22 TIE
								; bit21 TEDIE
								; bit20 TEIE
								
    movep #$000F38,x:PORT_C_CTRL_REG  ; Enable port C pins as ESAI by writing "1" to port control and 
    						   		  ; direction register - DSP56371 manual page 178      
    movep #$000F38,x:PORT_C_DIR_REG   ; Port C (ESAI) enabled								
    
    movep #000003,x:M_TSMA      ; M_TSMA = 0x3;
    movep #000000,x:M_TSMB      ; M_TSMB = 0x0;
            
    bset #0,x:M_TCR 
    bset #1,x:M_TCR 
    bset #2,x:M_TCR 
    bset #3,x:M_TCR             ; Enable ESAI transmitters 0,1,2,3
        
    movep #$000000,x:M_TX0		;zero out transmitter 0
	movep #$000000,x:M_TX1		;zero out transmitter 1
	movep #$000000,x:M_TX2		;zero out transmitter 2
	movep #$000000,x:M_TX3		;zero out transmitter 3
       
    move #TX_UNDERRUN_COUNTER,r5
    move #0,x0
    move x0,y:(r5)
    rts
 
;**************************************************************************
; ESAI 1 is used to receive data from 4 codecs
;**************************************************************************	        
setup_ESAI_1        
    movep #$000000,y:PORT_E_CTRL_REG  ; Disable port E   
    movep #$000000,y:PORT_E_DIR_REG 
     
    movep #$0C0200,y:M_RCCR_1     ; Receive clock control register  						
    							  ; Receive frame sync signal direction, FSR is an input (bit22=0)
								  ; Receive clock source direction, SCKR is an input (bit21=0)
								  ; Negative FSR polarity (bit19=1)
								  ; Data & FSR clocked in on rising edge(bit18=1)
								  ; 2 words per frame (bit13:9=00001)
        
    movep #$000000,y:M_SAICR_1    ; M_SAICR_1 = 0; ESAI Common Control Register 
                          
    movep #$717d00,y:M_RCR_1      ; M_RCR_1 = 0x717d00; ESAI Receive control Register  
								  ; RX0, RX1, RX2, RX3 disabled (bit3:0=0000)						
								  ; MSB shifted first (bit6=0)
								  ; word left-aligned (bit7=0)
								  ; network mode (bit9:8=01)
								  ; 32-bit slot length, 24-bit word length (bit14:10=11111)
								  ; word length frame sync (bit15=0)
								  ; frame sync occurs 1 clock cycle earlier (bit16=1)						
								  ; RIE, REDIE, REIE enabled (bit23:20=0111)
								  ; bit23 RLIE
								  ; bit22 RIE
								  ; bit21 REDIE
								  ; bit20 REIE
        
    movep #$0003C3,y:PORT_E_CTRL_REG  ; Enable port E pins as ESAI by writing "1" to port control and     			      			   				     
    			   				      ; direction register - DSP56371 manual page 230    
    movep #$0003C3,y:PORT_E_DIR_REG   ; Port E (ESAI) enabled
    
    movep #$000003,y:M_RSMA_1      	; M_RSMA_1 = 0x3;
    movep #$000000,y:M_RSMB_1       ; M_RSMB_1 = 0x0;  
            
    bset #0,y:M_RCR_1 
    bset #1,y:M_RCR_1  
    bset #2,y:M_RCR_1  
    bset #3,y:M_RCR_1               ; Enable ESAI receivers 0,1,2,3
    
    move #RX_OVERRUN_COUNTER,r5
    move #0,x0
    move x0,y:(r5)           
    rts
    
    endsec