
module rdrom_data(
    input                 clk    , 
    input                 rst_n  , 

    output    [31:0]    da_data   	
    );

//parameter
//频率调节控制
parameter  FREQ_ADJ = 8'd0;  //频率调节,FREQ_ADJ的越大,最终输出的频率越低,范围0~255

//reg define
reg    	[9:0]   freq_cnt  ;  	//频率调节计数器
reg 	[8:0] 	addsub_da ;  	//波形累加信号
reg  [9:0]    rd_addr;  	//读ROM地址
wire [31:0] da_data_med;
assign da_data=da_data_med;
//*****************************************************
//**                    main code
//*****************************************************
     

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)
        freq_cnt <= 10'd0;
    else if(freq_cnt == FREQ_ADJ)    
        freq_cnt <=10'd0;
    else         
        freq_cnt <= freq_cnt + 10'd1;
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)
        rd_addr <= 10'd0;
    else begin
        if(freq_cnt == FREQ_ADJ)
            rd_addr <= rd_addr + 10'd1;
        else
            rd_addr <= rd_addr;            
    end            
end

rom_ad_data rom_ad_data (
  .clka(clk),    // input wire clka
  .addra(rd_addr),  // input wire [10 : 0] addra
  .douta(da_data_med)  // output wire [23 : 0] douta
);

endmodule