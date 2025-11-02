module fft_test(
    input sys_clk  ,
    input sys_rst_n
    );

wire [31:0]  win_ad_data_out    ;         //采集后的adc输出数据
wire         ad_data_out_en  ;         //采集后的adc输出数据使能

wire [47:0] s_axis_data_tdata;   //fft数据通道的输入数据
wire        s_axis_data_tvalid;	 //fft数据通道的输入数据有效使能
wire        s_axis_data_tready;  //fft数据通道准备完成信号
wire        s_axis_data_tlast;   //fft数据通道接收最后一个数据标志信号
wire        m_axis_data_tvalid;  //fft数据通道的输出数据有效使能
wire [47:0] m_axis_data_tdata;   //fft数据通道的输出数据
wire        m_axis_data_tlast;   //fft数据通道发送最后一个数据标志信号
wire [23:0] m_axis_data_tuser;   //fft数据通道输出数据的状态信息
wire        fft_eop;             //取模后输出的终止信号

    wire          m_axis_data_tvalid_ch3;
     wire  [7 : 0]  m_axis_data_tdata_ch3_med;
     wire  [31 : 0]  m_axis_data_tdata_ch3;
 assign  m_axis_data_tdata_ch3 = m_axis_data_tdata_ch3_med << 16;    


    dds_compiler_0 multi_ch3(
        .aclk(sys_clk),                                // input wire aclk
        .m_axis_data_tvalid(m_axis_data_tvalid_ch3),    // output wire m_axis_data_tvalid
        .m_axis_data_tdata(m_axis_data_tdata_ch3_med),   // output wire [7 : 0] m_axis_data_tdata
        .m_axis_phase_tvalid(),
        .m_axis_phase_tdata()   
    );

//例化fifo控制模块，adc数据
fifo_windows_ctrl u_fifo_ctrl(
	.axi_clk			(sys_clk),         
	.sys_rst_n			(sys_rst_n),              //复位信号，低电平有效

	.ad_clk				(sys_clk),        //相位偏移后的25m时钟 
	.ad_data_in			(m_axis_data_tdata_ch3),            //AD输入数据 
    .data_32_en         (m_axis_data_tvalid_ch3),
    
	.s_axis_data_tready	(s_axis_data_tready), //fft数据通道准备完成信号
	.s_axis_data_tlast	(s_axis_data_tlast),  //fft数据通道接收最后一个数据标志信号

	.win_ad_data_out	(win_ad_data_out),        //采集后的adc输出数据
	.ad_data_out_en     (ad_data_out_en)      //采集后的adc输出数据使能
    
);	
//将采集后的adc输出数据有效使能赋给fft的输入数据有效使能
assign  s_axis_data_tvalid =  ad_data_out_en; 
//将采集后的adc输出数据补0赋给fft的输入数据
assign s_axis_data_tdata = {24'b0,win_ad_data_out[23:0]};  

//例化fft模块
xfft_0 xfft_0 (
  .aclk(sys_clk),                             //100m时钟               
  .aresetn(sys_rst_n),                             //复位信号，低电平有效           
  .s_axis_config_tdata(8'b1),                  //配置通道的输入数据，1：fft   0：ifft
  .s_axis_config_tvalid(1'b1),                 //配置通道的输入数据有效使能
  .s_axis_config_tready(),                     //外部模块准备接收配置通道数据
  
  .s_axis_data_tdata(s_axis_data_tdata),       //fft数据通道的输入数据               
  .s_axis_data_tvalid(s_axis_data_tvalid),     //fft数据通道的输入数据有效使能              
  .s_axis_data_tready(s_axis_data_tready),     //fft数据通道准备完成信号          
  .s_axis_data_tlast(s_axis_data_tlast),       //fft数据通道接收最后一个数据标志信号           
  
    
  .m_axis_data_tdata(m_axis_data_tdata),       //fft数据通道的输出数据              
  .m_axis_data_tuser(m_axis_data_tuser),       //fft数据通道输出数据的状态信息              
  .m_axis_data_tvalid(m_axis_data_tvalid),     //fft数据通道的输出数据有效使能              
  .m_axis_data_tready(1'b1),                   //外部模块准备接收数据通道数据
  .m_axis_data_tlast(m_axis_data_tlast),       //fft数据通道发送最后一个数据标志信号               
  
  .m_axis_status_tdata(),                      //fft状态数据通道输出数据
  .m_axis_status_tvalid(),                     //fft状态数据通道输出数据有效使能
  .m_axis_status_tready(1'b1),                 //外部模块准备接收状态数据
  .event_frame_started(),                      
  .event_tlast_unexpected(),         
  .event_tlast_missing(),               
  .event_status_channel_halt(),   
  .event_data_in_channel_halt(), 
  .event_data_out_channel_halt()
);   

 reg [15:0] cnt_fft=16'd0;
 always @(posedge  sys_clk) begin
   if(m_axis_data_tvalid==1)
        cnt_fft<=cnt_fft+1;
    else
        cnt_fft=16'd0;
 end
wire [31:0] fft_data;
wire fft_valid;

//例化数据取模模块
data_modulus  u_data_modulus(
    .clk					(sys_clk),
    .rst_n					(sys_rst_n),
                     
    .source_real			(m_axis_data_tdata[23:0]),    //实部 有符号数  开方最大支持输入48bits，这里将数据改为1 4 19 的24位signed类型
    .source_imag			(m_axis_data_tdata[47:24]),  //虚部 有符号数
    .source_eop				(m_axis_data_tlast),         //fft数据通道接收最后一个数据标志信号
    .fft_valid			(m_axis_data_tvalid),        //输出有效信号，FFT变换完成后，此信号置高，开始输出数据
    //取模运算后的数据接口     
    .fft_data		        (fft_data),                  //取模后的数据
    .data_eop				(fft_eop),                   //取模后输出的终止信号
    .data_valid				(fft_valid)                  //取模后的数据有效信号
);	





endmodule

