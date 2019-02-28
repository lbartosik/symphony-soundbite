	page		132,60	
	section		serial
	 
	nolist
	include "../../dsp_crt0/dsp_regs.equ"	
	include "../serial.equ"	
	list  
 
;**************************************************************************
; Global symbols
;**************************************************************************

	GLOBAL RS_RX_BIT_NUMBER,RS_RX_DATA
	GLOBAL RS_RX_FLAGS,RS_TX_FLAGS
	GLOBAL Frs_init_rx,Frs_init_tx
	GLOBAL Frs_rx,Frs_tx
	GLOBAL Frs_send,Fenable_rs_rx

;**************************************************************************
; Data in Y space
;**************************************************************************

	org y:0
	
RS_RX_DATA       ds 128
 
; RS232 Tx
RS_TX_BIT_NUMBER    ds 1            ; bit number to be transmitted     
RS_TX_NUM_OF_BYTES  ds 1            ; number of bytes to transmit
RS_TX_DATA_POINTER  ds 1            ; pointer to data to be transmitted
RS_TX_FLAGS         ds 1            ; tx flags
RS_TX_DROPPED_BYTES ds 1            ; number of dropped bytes

; RS232 Rx
RS_RX_BIT_NUMBER    ds 1    		; bit number to be received    
RS_RX_NUM_OF_BYTES  ds 1    		; number of received
RS_RX_DATA_POINTER  ds 1    		; pointer to received data
RS_RX_FLAGS         ds 1    		; rx flags


;**************************************************************************
; Code in P space
;**************************************************************************
	
	org p:

Frs_tx
	move a0,ssh 						 ; store accumulator on the stack
	move a1,ssh          
	move r7,ssh     					 ; store r7 on the stack
	  
	clr a                                ; clear accumulator
	move #RS_TX_BIT_NUMBER,r7   		 ; load address of RS tx bit number into r7	  
	move y:(r7),a1             		     ; load RS tx bit number into a1
	brset #RS_START_BIT,a1,tx_start_bit  ; check if we need to generate start bit
    brset #RS_STOP_BIT,a1,tx_stop_bit    ; check if we need to generate stop bit
	bra tx_data_bit
	
tx_start_bit
    bclr #RS_TX_PIN,y:PORT_F_DATA_REG    ; start bit means transition from logical 1 to 0
    lsl #$01,a                           ; shift RS tx bit number left by one and store it in the memory
    move a1,y:(r7)
	bra rs_tx_end
 
tx_stop_bit
    bset #RS_TX_PIN,y:PORT_F_DATA_REG    ; stop bit means transition from logical 0 to 1
    move #>$000001,a1                    ; reset RS tx bit number to 1 and store into memory
    move a1,y:(r7)+ 
    
    clr a	                             ; clear accumulator
    move y:(r7),a0                       ; get RS tx number of bytes
    dec a
    brclr #$02,sr,tx_next_byte           ; check if number of is not equal to zero 
    bclr #0,x:TIMER_TX_CTRL_AND_STATUS_REG	 ; there are no more bytes to transmit disable tx timer
    
    move #RS_TX_FLAGS,r7
    bset #BUFFER_STATUS,y:(r7)
    
    bra rs_tx_end
tx_next_byte
    move a0,y:(r7)+                      ; store number of bytes to transmit 
    clr a
    move y:(r7),a0                       ; increment data pointer and store it into the memory
    inc a
    move a0,y:(r7)
    bra rs_tx_end  

tx_data_bit    
	lsl #$01,a                           ; shift RS tx bit number left by one and store it in the memory
    move a1,y:(r7)
    
	move #RS_TX_DATA_POINTER,r7          ; get data to tansmit
	move y:(r7),a1
	move a1,r7
	move y:(r7),a1						 ; get byte to transmit
	brset #$00,a1,tx_pin_high
	bclr #RS_TX_PIN,y:PORT_F_DATA_REG    ; set Tx pin to low
	bra tx_data_bit_end 
tx_pin_high	
    bset #RS_TX_PIN,y:PORT_F_DATA_REG    ; set Tx pin to high
tx_data_bit_end
    lsr #$01,a
    move a1,y:(r7)     

rs_tx_end 
	move ssh,r7             ; restore r7 from the stack
	move ssh,a1             ; restore accumulator from the stack
    move ssh,a0    
    nop         
	rti

Frs_rx
	move a0,ssh 						 ; store accumulator on the stack
	move a1,ssh
	move x0,ssh                          ; store x0 on the stack          
	move r7,ssh     					 ; store r7 on the stack
	move r5,ssh                          ; store r5 on the stack
		
	clr a                                ; clear accumulator
	move #>0,x0                          ; clear x0
	move #RS_RX_BIT_NUMBER,r7   		 ; load address of RS rx bit number into r7	  
	move y:(r7),a1             		     ; load RS rx bit number into a1
	brset #RS_8TH_BIT,a1,rx_data_no_shift
	move #>$01,x0	
rx_data_no_shift 
	brset #RS_START_BIT,a1,rx_start_bit  ; check if this is start bit
    brset #RS_STOP_BIT,a1,rx_stop_bit    ; check if this is stop bit 
    bra rx_data_bit
	
rx_start_bit
    bclr #0,x:TIMER_RX_CTRL_AND_STATUS_REG					; disable Rx timer
    movep #TIMER_RX2_COMPARE_VALUE,x:TIMER_RX_COMPARE_REG	; load Rx timer compare register with the new value
    bset #0,x:TIMER_RX_CTRL_AND_STATUS_REG					; enable Rx timer    
    lsl #$01,a                           ; shift RS rx bit number left by one and store it in the memory
    move a1,y:(r7)
	bra rs_rx_end

rx_stop_bit  
    move #>$000001,a1                    ; reset RS rx bit number to 1 and store into memory
    move a1,y:(r7)+ 
    
    clr a	                             ; clear accumulator
    move y:(r7),a0                       ; get RS rx number of bytes, increase it by 1 and store it back into memory
    inc a
    ; dodac zabiezpieczenie do dlugosci
    move a0,y:(r7)+
    
    move y:(r7),a0                       ; get RS rx data pointer, increase it by 1 and store it back into memory                  
    inc a
    move a0,y:(r7)+
    
    bclr #0,x:TIMER_RX_CTRL_AND_STATUS_REG	; disable Rx timer
    movep #TIMER_RX1_COMPARE_VALUE,x:TIMER_RX_COMPARE_REG	
     
    move a0,r7
    move y:-(r7),a
    cmp #END_LINE,a
    brclr #02,sr,more_data   
     
    clr a
    move (r7)+
    move a,y:(r7)
       
    ; initialize control data for Rs Rx
    move #RS_RX_BIT_NUMBER,r7
    move #>$000001,x0
    move x0,y:(r7)+    
    move #>$000000,x0
    move x0,y:(r7)+         
    move #RS_RX_DATA,r5
    move r5,y:(r7)+
                
    move #RS_RX_FLAGS,r7
    bset #BUFFER_STATUS,y:(r7)           ; message is ready to be processed
    bra rs_rx_end
        
more_data
    movep #$000007,x:M_IPRC            	 ; enable IRQA triggered by a negative edge         
    bra rs_rx_end
    
rx_data_bit    
	lsl #$01,a                           ; shift RS rx bit number left by one and store it in the memory
    move a1,y:(r7)
       
	move #RS_RX_DATA_POINTER,r7          ; get pointer to data to be stored
	move y:(r7),a1
	move a1,r7
	move y:(r7),a1						 ; get byte to store data
		
	brset #RS_RX_PIN,y:PORT_F_DATA_REG,rx_pin_high
	bclr #7,a1    					 	 ; set bit to low
	bra rx_data_bit_end 
rx_pin_high	
    bset #7,a1    					     ; set bit to high
rx_data_bit_end              		   
    lsr x0,a    
    move a1,y:(r7)     

rs_rx_end 
    move ssh,r5             ; restore r5 from the stack
	move ssh,r7             ; restore r7 from the stack
	move ssh,x0             ; restore x0 from the stack
	move ssh,a1             ; restore accumulator from the stack
    move ssh,a0    
    nop         
	rti

Frs_send
    move r7,y:(r6)+ 
    move x0,y:(r6)+
        
    ; prepare data to be send through rs  
    move #RS_TX_BIT_NUMBER,r7
    move #>$000001,x0
    move x0,y:(r7)+       
    move a1,y:(r7)+        
    move b1,y:(r7)             
    bset #0,x:TIMER_TX_CTRL_AND_STATUS_REG				; enable Tx timer
    
    move #RS_TX_FLAGS,r7
    bclr #BUFFER_STATUS,y:(r7)
    
    move (r6)-
    move y:(r6)-,x0   
    move y:(r6),r7    
    rts
    
Fenable_rs_rx	
   	move r7,y:(r6)+    	
    
    movep #$000007,x:M_IPRC            	 ; enable IRQA triggered by a negative edge
    move #RS_RX_FLAGS,r7
    bclr #BUFFER_STATUS,y:(r7)
    
    move (r6)-  
    move y:(r6),r7    
	rts		 
 
Frs_init_rx
 	; set Rs Rx pin as input with logic "0"   							
	bclr #RS_RX_PIN,y:PORT_F_DATA_REG
    bset #RS_RX_PIN,y:PORT_F_CTRL_REG
    bclr #RS_RX_PIN,y:PORT_F_DIR_REG
	
	movep   #$300204,x:TIMER_RX_CTRL_AND_STATUS_REG
	movep   #0,x:TIMER_RX_LOAD_REG
	movep   #TIMER_RX1_COMPARE_VALUE,x:TIMER_RX_COMPARE_REG	
 
    ; initialize control data for Rs Rx
    move #RS_RX_BIT_NUMBER,r7
    move #>$000001,x0
    move x0,y:(r7)+    
    move #>$000000,x0
    move x0,y:(r7)+     
    
    move #RS_RX_DATA,r6
    move r6,y:(r7)+
   
    move #>0,x0 
    move x0,y:(r7)+     ; RS_RX_FLAGS
    move x0,y:(r7)+     ; RS_RX_DROPPED_BYTES
    move x0,y:(r7)+     ; RS_RX_DUMMY_BYTE    
 	rts
 
Frs_init_tx
  	; set Rs Tx pin as output with logic "1"   							
	bset #RS_TX_PIN,y:PORT_F_DATA_REG
    bclr #RS_TX_PIN,y:PORT_F_CTRL_REG
    bset #RS_TX_PIN,y:PORT_F_DIR_REG
	
	movep   #$300204,x:TIMER_TX_CTRL_AND_STATUS_REG
	movep   #0,x:TIMER_TX_LOAD_REG
	movep   #TIMER_TX_COMPARE_VALUE,x:TIMER_TX_COMPARE_REG
	
	move #RS_TX_DROPPED_BYTES,r7
    move #>$00,x0
    move x0,y:(r7)
    
    move #RS_TX_FLAGS,r7
    bset #BUFFER_STATUS,y:(r7)	
	rts 
	
	endsec