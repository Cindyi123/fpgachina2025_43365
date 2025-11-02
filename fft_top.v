/******
ȫ�����ݴ�����1 8 23 ��ʽ��32λsigned������
              31  30-23  22
�з�������ˣ��ֽ�����λ��M+Nλ�ٳ�
��ȡģ����ʱ���������֧������48bits�����ｫ���ݸ�Ϊ1 4 19 ��24λsigned����
****************/
module fft_top(
    input                   sys_clk     	,  //ϵͳʱ��
    input                   sys_rst_n   	,  //ϵͳ��λ���͵�ƽ��Ч

    input                   Rx_0            , 
    output                  Tx_0            , 
    output                  Clk_0            , 
    output                  CS               ,

    output  [31:0]          ad_data0        ,
    output  [31:0]          ad_data1     ,
    output  [31:0]          ad_data2        ,
    output                  en_Ain0       ,
    output                  en_Ain1       ,
    output  [31:0]          fft_data        ,           //ȡģ�����Ч����
    output                  fft_valid        ,  //ȡģ���������Ч�ź�
    input   [31:0]          P_target        ,
    output  [31:0]          i_current       ,
    input   [31:0]          P_measure
    );

wire key_pause;


//wire define    
wire        clk_100m;            //100mʱ��
wire        clk_50m;             //50mʱ��
wire        clk_25m;             //25mʱ�� 
wire        clk_25m_deg;         //��λƫ�ƺ��25mʱ�� 
wire        locked;              //pll����ȶ��ź�
wire        rst_n;               //��λ�źţ��͵�ƽ��Ч


wire [31:0]  Ain1             ;
wire [31:0]  Ain0             ;

wire [31:0]  win_ad_data_out    ;         //�ɼ����adc�������
wire         ad_data_out_en  ;         //�ɼ����adc�������ʹ��

wire [47:0] s_axis_data_tdata;   //fft����ͨ������������
wire        s_axis_data_tvalid;	 //fft����ͨ��������������Чʹ��
wire        s_axis_data_tready;  //fft����ͨ��׼������ź�
wire        s_axis_data_tlast;   //fft����ͨ���������һ�����ݱ�־�ź�
wire        m_axis_data_tvalid;  //fft����ͨ�������������Чʹ��
wire [63:0] m_axis_data_tdata;   //fft����ͨ�����������
wire        m_axis_data_tlast;   //fft����ͨ���������һ�����ݱ�־�ź�
wire [23:0] m_axis_data_tuser;   //fft����ͨ��������ݵ�״̬��Ϣ
wire        fft_eop;             //ȡģ���������ֹ�ź�

// 优化后的窗函数乘法
//assign win_ad_data_out_med = win_data * ad_data_out;
//assign win_ad_data_out = win_ad_data_out_med[54:23];


wire    [15:0]     lcd_id  ;

wire                                        touch_valid                ;
reg                                        touch_valid_0                ;
reg                                        touch_valid_1                ;
wire                       [15:0]           x_touch_data               ;
wire                       [15:0]           y_touch_data               ;
//*****************************************************
//**                    main code
//*****************************************************


//���ɼ����adc������ݲ�0����fft����������
assign s_axis_data_tdata = {24'b0,win_ad_data_out[23:0]};  

//���ɼ����adc���������Чʹ�ܸ���fft������������Чʹ��
assign  s_axis_data_tvalid =  ad_data_out_en; 

                                               
/*
rdrom_data u_ad_data(
    .clk     (sys_clk),  	//ʱ��
    .rst_n   (sys_rst_n),  	//��λ�źţ��͵�ƽ��Ч            
    .da_data (Ain) 	        //�����DA������  
    );
*/
ads1258 #(.Fs_Hz(1000)) u_ads1258 
(
    .sysclk    (sys_clk),
    .locked    (sys_rst_n),
    .Rx_0      (Rx_0 ),
    .Tx_0      (Tx_0 ),
    .Clk_0     (Clk_0),
    .CS        (CS   ),
    .en_Ain0   (en_Ain0   ),
    //.en_Ain1   (en_Ain1  ),
    .Ain0       (Ain0   ) 
    //.Ain1       (Ain1   )
);  
reg [31:0] ad_data0_med ;
reg [31:0] ad_data1_med ;
reg [31:0] ad_data2_med ;
assign en_Ain1 = en_Ain0; 

assign ad_data0=ad_data0_med[23]? {9'b1,ad_data0_med[22:0]}:{9'b0,ad_data0_med[22:0]} ;
assign ad_data1=ad_data1_med[23]? {9'b1,ad_data1_med[22:0]}:{9'b0,ad_data1_med[22:0]} ;//ad_data1=Ain;//
assign ad_data2=ad_data2_med[23]? {9'b1,ad_data2_med[22:0]}:{9'b0,ad_data2_med[22:0]} ;

    always @(posedge sys_clk)           
        begin                                        
            if(!sys_rst_n)   begin                            
                ad_data0_med = 32'b111;
                ad_data1_med = 32'b111;
                ad_data2_med = 32'd0   ; 
            end                                  
            else if(en_Ain0 ==1'b1) begin
                if (Ain0[31:24]== 8'h88) begin
                    ad_data0_med <= Ain0;
                end
                else if (Ain0[31:24]== 8'h89) begin
                    ad_data1_med <= Ain0;
                end
                else if (Ain0[31:24]== 8'h8A) begin
                    ad_data2_med <= Ain0;
                end
                else begin
                    ad_data0_med <= ad_data0_med ;
                    ad_data1_med <= ad_data1_med ;
                    ad_data2_med <= ad_data2_med ;
                end
            end                                                                        
            else begin
                ad_data0_med <= ad_data0_med ;
                ad_data1_med <= ad_data1_med ;
                ad_data2_med <= ad_data2_med ;
            end 
        end                                          

//wire [31:0] P_measure ;
//wire [31:0] P_target  ;
//wire [31:0] i_current ;

PID_UV_LED PID_UV_LED(
    .clk       (sys_clk)    ,             
    .rst_n     (sys_rst_n)   , 
    .P_measure (P_measure)           ,       
    .P_target  (P_target)           , 
    .i_current (i_current) 
);

//����fifo����ģ�飬adc����
fifo_windows_ctrl u_fifo_ctrl(
	.axi_clk			(sys_clk),         
	.sys_rst_n			(sys_rst_n),              //��λ�źţ��͵�ƽ��Ч

	.ad_clk				(sys_clk),        //��λƫ�ƺ��25mʱ�� 
	.ad_data_in			(ad_data1),            //AD�������� 
    .data_32_en         (en_Ain0),
    
	.s_axis_data_tready	(s_axis_data_tready), //fft����ͨ��׼������ź�
	.s_axis_data_tlast	(s_axis_data_tlast),  //fft����ͨ���������һ�����ݱ�־�ź�

	.win_ad_data_out	(win_ad_data_out),        //�ɼ����adc�������
	.ad_data_out_en     (ad_data_out_en)      //�ɼ����adc�������ʹ��
    
);	

//����fftģ��
xfft_0 xfft_0 (
  .aclk(sys_clk),                             //100mʱ��               
  .aresetn(sys_rst_n),                             //��λ�źţ��͵�ƽ��Ч           
  .s_axis_config_tdata(8'b1),                  //����ͨ�����������ݣ�1��fft   0��ifft
  .s_axis_config_tvalid(1'b1),                 //����ͨ��������������Чʹ��
  .s_axis_config_tready(),                     //�ⲿģ��׼����������ͨ������
  
  .s_axis_data_tdata(s_axis_data_tdata),       //fft����ͨ������������               
  .s_axis_data_tvalid(s_axis_data_tvalid),     //fft����ͨ��������������Чʹ��              
  .s_axis_data_tready(s_axis_data_tready),     //fft����ͨ��׼������ź�          
  .s_axis_data_tlast(s_axis_data_tlast),       //fft����ͨ���������һ�����ݱ�־�ź�           
    
  .m_axis_data_tdata(m_axis_data_tdata),       //fft����ͨ�����������              
  .m_axis_data_tuser(m_axis_data_tuser),       //fft����ͨ��������ݵ�״̬��Ϣ              
  .m_axis_data_tvalid(m_axis_data_tvalid),     //fft����ͨ�������������Чʹ��              
  .m_axis_data_tready(1'b1),                   //�ⲿģ��׼����������ͨ������
  .m_axis_data_tlast(m_axis_data_tlast),       //fft����ͨ���������һ�����ݱ�־�ź�               
  
  .m_axis_status_tdata(),                      //fft״̬����ͨ���������
  .m_axis_status_tvalid(),                     //fft״̬����ͨ�����������Чʹ��
  .m_axis_status_tready(1'b1),                 //�ⲿģ��׼������״̬����
  .event_frame_started(),                      
  .event_tlast_unexpected(),         
  .event_tlast_missing(),               
  .event_status_channel_halt(),   
  .event_data_in_channel_halt(), 
  .event_data_out_channel_halt()
);   

//��������ȡģģ��
data_modulus  u_data_modulus(
    .clk					(sys_clk),
    .rst_n					(sys_rst_n),
                     
    .source_real			(m_axis_data_tdata[23:0]),    //ʵ�� �з�����  �������֧������48bits�����ｫ���ݸ�Ϊ1 4 19 ��24λsigned����
    .source_imag			(m_axis_data_tdata[47:24]),  //�鲿 �з�����
    .source_eop				(m_axis_data_tlast),         //fft����ͨ���������һ�����ݱ�־�ź�
    .fft_valid			(m_axis_data_tvalid),        //�����Ч�źţ�FFT�任��ɺ󣬴��ź��øߣ���ʼ�������
    //ȡģ���������ݽӿ�     
    .fft_data		        (fft_data),                  //ȡģ�������
    .data_eop				(fft_eop),                   //ȡģ���������ֹ�ź�
    .data_valid				(fft_valid)                  //ȡģ���������Ч�ź�
);	


	
endmodule
