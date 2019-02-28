	page		132,60	
	section		main
	  
	nolist
	include "..\dsp_regs.equ"	
	include "..\..\main\serial.equ"	
	include "..\..\main\codecs.equ"	
	include "..\..\main\esai.equ"	
	include "..\..\main\dma.equ"	
	list 
             
; ###################################################################
;
; Default Hardware Memory Map for DSP56371(MS=1, MSW0=1, MSW1=1)
;
;            Program               X Data                Y Data
; $ffffff.-------------.$ffffff.-------------.$ffffff.-------------.
;        |             |       |  Int. I/O   |       |  Int. I/O   |
;        | Program ROM |$ffff80|_____________|$ffff80|_____________|
; $fff0c0|_____________|       |             |       |             |
;        |             |       |  Ext. N/M   |       |  Ext. N/M   |
;        |Bootstrap ROM|$fff000|_____________|$fff000|_____________| 
; $ff0000|_____________|       |             |       |
;        |             |       | Int. Rsrvd. |       | Int. Rsrvd. |
;        |             |$ff0000|_____________|$ff0000|_____________|
;        |             |       |             |       |             |
;        |             |$010000|_____________|$016000|_____________|
;        |             |       |             |       |             |
;        |             |       |  X Data RAM |       |  Y Data RAM |
;        |             |       |    16 K     |       |     40 K    |
;        |             |$00C000|_____________|$00C000|_____________| 
;        |             |       |             |       |             | 
;        |             |       |  32 K ROM   |       |  32 K ROM   |
; $003000|_____________|$004000|_____________|$004000|_____________|
;        |             |       |             |       |             |
;        |             |$003000|_____________|$002000|_____________|
;        |   Internal  |       |             |       |             |
;        | Program RAM |       |             |       |             |
;        |     12 K    |       |  X Data RAM |       |  Y Data RAM |
;        |             |       |     12 K    |       |     8 K     |
; $000000|_____________|$000000|_____________|$000000|_____________|
;
; N/M = Not Mapped  
; 
; ###################################################################

;**************************************************************************
; Global symbols
;**************************************************************************
	GLOBAL RS_TX_FLAGS,RS_RX_FLAGS,RS_RX_DATA
		
    org x:$00FF00 

	; Extended stack space is locted in upper part of X memory 
	; and it spans from 0x00FF00 to 0x010000 (256 words)
EXTENDED_STACK      ds EXTENDED_STACK_SIZE

    org x:
    
FILTER_COEFFS dc 0.0083,0.0227,0.0102,-0.0259,-0.0126,0.0472,0.0163,-0.0951,-0.0193,0.3145,0.5203,0.3145,-0.0193,-0.0951,0.0163,0.0472,-0.0126,-0.0259,0.0102,0.0227,0.0083 
FILTER_COEFFS_NUM dc 21                                                          
 
;**************************************************************************
; Intterupt vectors
;**************************************************************************

	org p:I_RESET_VECTOR						; hardware reset interrupt
	jmp	Fmain		 		
  
 	org p:I_IRQA_VECTOR             			; IRQA interrupt 	
    bclr #0,x:M_IPRC   		                    ; disable IRQA triggered by a negative edge      
    bset #0,x:TIMER_RX_CTRL_AND_STATUS_REG		; enable Rx timer    
  
   	org p:I_IRQB_VECTOR
 	nop
 	nop
  
	org p:I_TIMER_RX_CMP_VECTOR                 ; timer Rx compare interrupt
	bsr Frs_rx
  
	org p:I_TIMER_TX_CMP_VECTOR     			; timer Tx compare interrrupt
	bsr Frs_tx 
	
	org p:I_ESAI_TX_VECTOR
	bsr Fesai_tx
	   
	org p:I_ESAI_TX_EVEN_VECTOR 
	bsr Fesai_tx_even
	          
    org p:I_ESAI_TX_EXCEPTION_VECTOR
    bsr Fesai_tx_exception
    
    org p:I_ESAI_RX_VECTOR     
    bsr Fesai_rx
    
    org p:I_ESAI_RX_EVEN_VECTOR
    bsr Fesai_rx_even
    
    org p:I_ESAI_RX_EXCEPTION_VECTOR
    bsr Fesai_rx_exception
    
 	     
    org p:I_DMA0_VECTOR
   	bsr Fcopy_data
     
 
 
;********************************************************************
; Highest memory address is $016000 because memory locations from
; $016000 to $ffffff are either not mapped to external memory or
; reserved.
;********************************************************************
TOP_OF_MEMORY	equ	$016000
	
;********************************************************************
; The following varaibles are used for dynamic memory allocation

	org y:

; __stack_safty: Since dynamic memory and the stack grow towards each other 
; This constant tells brk and sbrk what the minimum amount of space should
; be left between the top of stack during the brk or sbrk call and the end 
; of any allocated memory.
	global F__stack_safety
F__stack_safety		dc	1024

; __mem_limit: a constant telling brk and sbrk where the end of available 
;	memory is.
	global F__mem_limit
F__mem_limit 		dc	TOP_OF_MEMORY

; __break: pointer to the next block of memory that can be allocated
;	The heap may be moved by changing the initial value of __break.
;	This is the base of the heap.
	global F__break
F__break			dc	TOP_OF_MEMORY

; __y_size: the base of dynamic memory.
	global F__y_size
F__y_size			dc	$00C000

; errno: error type: set by some libraries
	global	Ferrno
Ferrno  			dc	$0

; __max_signal the highest possible signal vector offset that might
;	be generated by the cpu. 
	global	F__max_signal
F__max_signal		dc	$fe
	 
;**************************************************************************
; Main entry point
;**************************************************************************

	org	p:$100   
	global Fmain 
	                   
Fmain  
	move	#$0,vba			; Vector Base Address: 0		
	move	#$0,sp			; Stack Pointer: 0
	move	#$0,sc			; Stack Counter: 0
	reset
  
	ori		#$03,mr					; mask interrupts levels 0,1,2 
	movep	#$04611d,x:PLL_CTRL_REG ; set PLL half speed, 89,088 Mhz
	rep		#$fff					; delay a bit for PLL to settle...
	nop 	

    ; We can reset omr because default size of program  space is not enough
    ; to accomodate the code, therefore debugger executes two additional
    ; commands before loading code in order to extend program space
    ; M p:2 0x0AFA75
    ; M p:3 0x0AFA76
;	move	#0,omr					; reset omr 
	   
	move 	#$c00300,sr				; reset sr 
	movep	#$04601d,x:PLL_CTRL_REG ; set PLL to full speed, 178,176 Mhz
	rep		#$fff					; delay a bit for PLL to settle...
	nop
    
    ; CONFIGURE EXTENDED HARDWARE STACK
    movec #SZ_REGISTER_VALUE,sz      ; initialize hardware stack extension
    movec #EXTENDED_STACK,ep     
    bclr #16,omr					; stack extension will be located in x memory space
    bset #20,omr  					; enable stack extension
          
    ; CONFIGURE PINS AND INITIALIZE AK4584 CODEC       
    bsr initialize_AK4584    ; configure pins to coomunicate with AK4584 vodec
    bsr configure_AK4584      ; configure AK4584 codec
        
    ;move #$300,r6			
	;bsr	GET_REGS_AK4584		; dump AK4584 register bank to x:
    
    ; CONFIGURE ESAI and ESAI_1 ports
   	bsr setup_ESAI_0
   	bsr setup_ESAI_1
   	;bsr INIT_ESAIS 
                                           
    ; CONFIGURE AND INITIALIZE SERIAL DRIVER
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
    move r6,y:(r7)  
      
    bsr Frs_init_rx             ; initialize Rx side of RS
  	bsr Frs_init_tx				; initialize Tx side of RS    
    
    ; initalize rx data pointers
    move #RX_DATA_LEFT_CHANNEL,r6  
    move r6,y:RX_DATA_LEFT_PTR
    move #RX_DATA_RIGHT_CHANNEL,r6   
    move r6,y:RX_DATA_RIGHT_PTR
    
    ; initalize DMA 0 channel
  
    ;movep #>0,x:DMA_DSR0        ; DMA source address register
    
    ;movep #DMA_TEST,x:DMA_DDR0  ; DMA destination address register
    
    ;movep #$C50855,x:DMA_DCR0   ; DMA control register
    
    ;movep #$001002,x:DMA_DCO0   ; DMA counter register
    
    ;movep #$000008,x:DMA_DOR0
     
           
    ; SET SOFTWARE STACK AND ADRESSING TO LINEAR                                                                                    
    move  y:F__y_size,r6        ; to change the base of the stack, change the value loaded 
                                ; into the stack pointer r6  
    bsr F__init_c_vars          ; initialize c variables    
    
    move  #-1,m0
   	move  m0,m1
   	move  m0,m2
   	move  m0,m3 
   	move  m0,m4 
   	move  m0,m5
   	move  m0,m6
   	move  m0,m7 
   	       	    	   	      	       	   	 
   	; ENABLE INTERRUPTS
    movep	#$000D03,x:M_IPRP   ; enable triple timer interrupt and set its priority to 0    
                                ; enable ESAI and ESAI_1 interrupts and set their priority to 2          
    movep   #$000005,x:M_IPRC   ; enable IRQA triggered by a negative edge, set its priority to 0
                                ; IRQA interrupt is used by Rs Rx side   
                                
    ; IRQB
    ;bset #3,x:M_IPRC
    ;bset #4,x:M_IPRC
    ;bset #5,x:M_IPRC                                    
            
    ; DMA channel 0        
    ;bset #12,x:M_IPRC                                
	;bset #13,x:M_IPRC                         
                                                                
    andi    #$FC,mr				; enable all interrupts - levels 0,1,2
  	  	 
;**************************************************************************        
; Main loop 
;**************************************************************************        	
  
LOOP	
	nop  
	bsr Fmain_loop
	 	   
	.if Y:ENABLE_PROCESSING <NE> #0 THEN
  	.if Y:PROCESS_DATA_FLAG <NE> #0 THEN		; When PROCESS_DATA flag becomes non-zero, it is time to start processing the current set of samples
	
	move #CHANNEL_BUFFER_SIZE,n2
	move #RX_BUFFER_SIZE-1,m2
	
    move y:RX_DATA_RIGHT_PTR,r2	
	move #TX_DATA_RIGHT_CHANNEL,r3
	 
	do #4,_repeat_right
	move y:(r2)+n2,x0
	move x0,y:(r3)+	
_repeat_right
	 	 
	move y:RX_DATA_LEFT_PTR,r2	
	move #TX_DATA_LEFT_CHANNEL,r3
	
	do #4,_repeat_left
	move y:(r2)+n2,x0
	move x0,y:(r3)+	
_repeat_left

	move #-1,m2
	move #0,n2

;    move #FILTER_COEFFS,r4
;    move #RX_DATA_LEFT_CHANNEL,r1
    
;    move x:(r4)+,x0
;    move y:(r1)+,y0
 
;    clr a
            
;	do #21,_filter_loop
;	mac x0,y0,a x:(r4)+,x0 y:(r1)+,y0     
;_filter_loop

;	move #TX_DATA_LEFT_CHANNEL,r4
;	move #0,x0
;	move x0,y:(r4)

	move	#$0,x0
	move	x0,Y:PROCESS_DATA_FLAG
	 
	.endi
	.endi
	
	jmp	LOOP	; jump back to LOOP, doing this endlessly
 
Fcopy_data	
    reset
	nop
	nop
	nop
	nop
	
	rti
  
  
;**************************************************************************        
; Interrupt routines
;**************************************************************************   	
 
Fesai_tx_exception
    move r1,ssh
  
  	bclr #14,x:M_SAISR  	
  	move y:TX_UNDERRUN_COUNTER,r1
  	move (r1)+
  	move r1,y:TX_UNDERRUN_COUNTER
  	
  	move ssh,r1  
  	 
; ESAI transmit odd data (right channel)
Fesai_tx
   	move r7,ssh     		; store r7 on the stack   
   
    move #TX_DATA_RIGHT_CHANNEL,r7
    movep y:(r7)+,x:(M_TX0)
    movep y:(r7)+,x:(M_TX1)
    movep y:(r7)+,x:(M_TX2)
    movep y:(r7)+,x:(M_TX3)
      
    move #$ffffff,r7
	move r7,y:PROCESS_DATA_FLAG
               
    move ssh,r7             ; restore r7 from the stack	
    nop
    rti
    
; ESAI transmit even data (left channel)
Fesai_tx_even 
	move r7,ssh     		; store r7 on the stack
    
    move #TX_DATA_LEFT_CHANNEL,r7
    movep y:(r7)+,x:(M_TX0)
    movep y:(r7)+,x:(M_TX1)
    movep y:(r7)+,x:(M_TX2)
    movep y:(r7)+,x:(M_TX3)
    
    move ssh,r7             ; restore r7 from the stack
    nop
    rti
     
Fesai_rx_exception 
    move r1,ssh    
    
  	bclr #7,y:M_SAISR_1	  	  	
  	move y:RX_OVERRUN_COUNTER,r1
  	move (r1)+
  	move r1,y:RX_OVERRUN_COUNTER
  	
  	move ssh,r1  	         
 
; ESAI receive odd data (right channel)
Fesai_rx
   	move r7,ssh     		; store r7 on the stack   
   	move m7,ssh             ; store m7 on the stack
   	move n7,ssh             ; store n7 on the stack

    move y:RX_DATA_RIGHT_PTR,r7         
    move #RX_BUFFER_SIZE-1,m7
    move #CHANNEL_BUFFER_SIZE,n7  
    move (r7)+   
    
    movep y:M_RX0_1,y:(r7)+n7
    movep y:M_RX1_1,y:(r7)+n7
    movep y:M_RX2_1,y:(r7)+n7
    movep y:M_RX3_1,y:(r7)+n7
          	       	    	   	       	   
    move r7,y:RX_DATA_RIGHT_PTR   
       
    move ssh,n7
    move ssh,m7      
    move ssh,r7             ; restore r7 from the stack	
    nop
    rti
     
; ESAI receive even data (left channel)
Fesai_rx_even
   	move r7,ssh     		; store r7 on the stack   
   	move m7,ssh             ; store m7 on the stack
   	move n7,ssh             ; store n7 on the stack
           
    move y:RX_DATA_LEFT_PTR,r7         
    move #RX_BUFFER_SIZE-1,m7
    move #CHANNEL_BUFFER_SIZE,n7
    move (r7)+ 
     
    movep y:M_RX0_1,y:(r7)+n7
    movep y:M_RX1_1,y:(r7)+n7
    movep y:M_RX2_1,y:(r7)+n7
    movep y:M_RX3_1,y:(r7)+n7
        	       	    	   	       	  
    move r7,y:RX_DATA_LEFT_PTR   
     
    move ssh,n7
    move ssh,m7      
    move ssh,r7             ; restore r7 from the stack	
    nop
    rti
     
    endsec

;********** *****************************************************
; Crt0 functions
;***************************************************************

	section	time_counter
	org	y:
	global	F__time
F__time
	dc	0
	endsec

	section	io_primitives
	org	p:
	nop
	
	global	F__send
F__send	
	nop
	rts
	nop
	nop
	
	global	F__receive
F__receive
	nop
	rts
	nop
	endsec
 
   section init_table
    org p:
    xdef    F__begin_init_table
F__begin_init_table
    dc (-1)
    endsec

   section cinit
    org     p:
    xref  F__begin_init_table
    global  F__init_c_vars
F__init_c_vars   
	clr   a                     
	clr   b
    move  #$ffffff,m0
    move  m0,m1
    move  m0,m2
	move  #F__begin_init_table,r0
 
    do    forever,_lab1
	; p:(r0)      destination start          
	; p:(r0+1)    source start               
	; p:(r0+2)    size of source block size  
	; p:(r0+3)    size zero initialized block

    movem p:(r0)+,r1            ; destination start
    lua   (r1)+,b
    tst   b
    nop
    brkeq
    movem p:(r0)+,r2        ; source start           
    movem p:(r0)+,r3        ; size of expicitly initialized block
    movem p:(r0)+,r4        ; size of zero initialized block

    do    r3,_lab2
    movem p:(r2)+,x0
    move  x0,y:(r1)+
    nop
_lab2                
    do    r4,_lab3
    move  a1,y:(r1)+
_lab3   
    nop
_lab1
   rts     
    
    global	F__crt0_end
F__crt0_end	
	stop			; all done 
 
 	endsec
