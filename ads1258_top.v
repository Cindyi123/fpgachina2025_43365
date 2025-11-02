`timescale 1ns / 1ps

module ads1258_top(
   input            sys_clk     ,    
   input            sys_rst_n       ,   
   input            Rx_0       , 
   output           Tx_0       , 
   output           Clk_0       , 
   output           CS          , 
   output           en_Ain0      , 
   output           en_Ain1     ,
   output [31:0]    ch0_reg_32 ,
   output [31:0]    ch1_reg_32   
    );

 wire  [7:0]       ch1_sig ;
 wire  [7:0]      ch1_reg_8 ;

 wire           data_8_en;

/*
parameter Vef=32'd ;  //2.5057*2^23   
wire [63:0] ads_data_med,Ain_med; 
wire [31:0] Ain;


assign Ain_med = Ain[23]? {32'hffffffff,Ain}  :  Ain;
assign ads_data_med = Ain_med * Vef ;
assign ads_data     = ads_data_med[54:23];
*/
 

        
ads1258 u_ads1258
(
    .sysclk     (sys_clk    ),
    .locked     (sys_rst_n     ),
    .Rx_0       (Rx_0       ),
    .Tx_0       (Tx_0       ),
    .Clk_0      (Clk_0      ),
    .CS         (CS         ),
    .en_Ain0    (en_Ain0    ),
    .en_Ain1    (en_Ain0    ),
    .Ain0        (  ch0_reg_32  ),
    .Ain1        (  ch1_reg_32  )
);


/*
uart_test U_uart(
	    .clk50      (sys_clk)  ,                     //50Mhz clock
		.reset_n    (sys_rst_n)   ,	  
		.ch1_dec    (ch1_reg_32)  , 
		.data_32_en    (data_32_en)  ,
		//.data_8_en 	(data_8_en),			       
        .tx		   (UartTx)
);

 SPI_ADS1258_X3 SPI_ADS1258_X3(
        .CLOCK         ( sys_clk),  // sys_clk   
        .RST           ( locked),  // locked 
        .data_8_en     (data_8_en),   
        .READ_CODE_0   (ch1_reg ),  // Rx_0      
        .uCS_0         ( CS),  // Tx_0      
        .CLK_0         (Clk_0 ),  // Clk_0     
        .TX_0          (Tx_0 ),  // CS        
        .RX_0          (Rx_0)    //  ch1_reg  
 );
 */                                         
 

    
    
endmodule
