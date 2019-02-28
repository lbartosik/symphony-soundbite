#ifndef MAIN_H_
#define MAIN_H_


#define RS_TX_READY 0x1 
#define RS_RX_READY 0x1 
#define RS_READY 0x1
    
#define TRUE 0x1
#define FALSE 0x0

#define PLL_REG 0xFFFFFD
#define READ_REG(value) (*((volatile int*)(value)))
 
char init = FALSE;                                                  
char data[] = {'d', 's', 'p', '>',0x0d, 0x0a};
char rs_data[128] = {};
      
extern void rs_send(int x, char* data) __asm("Frs_send"); 
extern volatile void enable_rs_rx() __asm("Fenable_rs_rx"); 
extern volatile int rs_tx_flags __asm("RS_TX_FLAGS");  
extern volatile int rs_rx_flags __asm("RS_RX_FLAGS");  
extern vlatile char rs_rx_data[] __asm("RS_RX_DATA");
extern volatile int esai_tx_underrun __asm("TX_UNDERRUN_COUNTER"); 
extern volatile int esai_rx_overrun __asm("RX_OVERRUN_COUNTER");  
extern volatile int enable_processing __asm("ENABLE_PROCESSING");
    
void display_esai_stats();
void display_dsp_frequency();
void enable_disable_processing(unsigned int flag);
void show_processing_status();
void help();

#endif /*MAIN_H_*/
