#include <string.h>
#include <stdarg.h>
#include "../snprintf.h" 
#include "../main.h"              
                                                                                                        
int main_loop()    
{                        	              
    if (init == FALSE)
    {
    	if ((rs_tx_flags & RS_TX_READY) == RS_READY)
        {   
        	snprintf(rs_data,128,"dsp>");         	        	
        	rs_send(strlen(rs_data), rs_data);
        	init = TRUE;
        }             
    }      
              
    if ((rs_rx_flags & RS_RX_READY) == RS_READY)       
    {		     
    		      	    
	    	if ((rs_tx_flags & RS_TX_READY) == RS_READY)
	        {        	        	        	
	        	if (strncmp(rs_rx_data,"show cpu frequency\r", 19) == 0)  
	        	{        	         		    
	        		display_dsp_frequency();      	         			
	        	}
	        	else if (strncmp(rs_rx_data,"show esai stats\r", 16) == 0)  
	        	{        	         		
	        		display_esai_stats();      	         			
	        	}
	        	else if (strncmp(rs_rx_data,"enable processing\r", 18) == 0)  
	        	{    
	        		enable_disable_processing(0x1);    	          			        	     	         		
	        	}
	        	else if (strncmp(rs_rx_data,"disable processing\r", 19) == 0)  
	        	{    
	        		enable_disable_processing(0x0);    	         			        	     	         		
	        	}	        	
	        	else if (strncmp(rs_rx_data,"show processing status\r", 23) == 0)  
	        	{    
	        		show_processing_status();    	         			        	     	         		
	        	}
	        	else if(strncmp(rs_rx_data,"help\r", 5) == 0)  
	        	{    
	        		help();    	         			        	     	         		
	        	}	        		        		       
	        	else if (strncmp(rs_rx_data,"\r", 1) == 0)  
    			{
    				snprintf(rs_data,128,"\n\rdsp>"); 
    			}    			
    			else       
	        	{
	        		snprintf(rs_data,128,"\n\runknown command\n\rdsp>"); 
	        	} 
	        	
	        	rs_send(strlen(rs_data), rs_data);
	        }     
        	         
        enable_rs_rx();
    }                      
}    
                                
int get_xmem(int location)
{
	int i;
	__asm("move x:(%1),%0" : "=A" (i) : "A" (location) );
	return (i);
}

int get_ymem(int location)
{
	int i;
	__asm("move y:(%1),%0" : "=A" (i) : "A" (location) );
	return (i);
}
 
void display_dsp_frequency()
{
	int pll_value;
	int predivider_factor;
	int output_divider_factor;
	int division_factor;
	int multiplication_factor;
	float pll_frequency;

	/* get PLL settings from the PLL register */
	pll_value = get_xmem(PLL_REG);
	
	/* get predivider factor bits 16 - 20 */
	predivider_factor = (pll_value & 0x1F0000) >> 16;
	  
	/* get output dividder factor bits 14 - 15 */
	output_divider_factor = (pll_value & 0x00C000) >> 14;
	
	/* get division factor bits 8 - 10 */
	division_factor = (pll_value & 0x000700) >> 8;
	division_factor = 2^division_factor;
	
	/* get multiplication factor bits 0 - 7 */
	multiplication_factor = pll_value & 0x0000FF;  
	
	pll_frequency = (24.576 * multiplication_factor * 2) / (predivider_factor * division_factor * 1);
        
    snprintf(rs_data,128,"\n\rCpu frequency : %d Mhz\n\rdsp>", (int)pll_frequency);
} 
 
void display_esai_stats()
{
	snprintf(rs_data,128,"\n\rESAI statistics\n\rTx underrun : %d\n\rRx overrrun : %d\n\rdsp>", esai_tx_underrun, esai_rx_overrun);
} 
 
void enable_disable_processing(unsigned int flag)
{
	if (flag > 0)
	{
		enable_processing = 0xFFFFFF;
		snprintf(rs_data,128,"\n\rProcessing enabled\n\rdsp>");
	}
	else
	{
		enable_processing = 0;
		snprintf(rs_data,128,"\n\rProcessing disabled\n\rdsp>");
	}	
}
     
void show_processing_status()
{
	if (enable_processing != 0)
	{
		snprintf(rs_data,128,"\n\rProcessing is enabled\n\rdsp>");
	}
	else
	{
		snprintf(rs_data,128,"\n\rProcessing is disabled\n\rdsp>");
	}	
}

void help()
{
	snprintf(rs_data,128,"\n\rAvailable commands:\n\r"
	"show cpu frequency\n\r"
	"show esai stats\n\r"
	"enable processing\n\r"
	"disable processing\n\r"
	"show processing status\n\r"
	"help\n\r"
	"\n\rdsp>");	
}
	


             