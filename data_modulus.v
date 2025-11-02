
module data_modulus(
    input             clk,
    input             rst_n,
    //FFT ST接口
    input   [23:0]     source_real,   //实部 有符号数
    input   [23:0]     source_imag,   //虚部 有符号数
    input             source_eop,    //fft数据通道接收最后一个数据标志信号
    input             fft_valid,  //输出有效信号，FFT变换完成后，此信号置高，开始输出数据
    //取模运算后的数据接口
    output   [31:0]    fft_data,  //取模后的数据
    output            data_eop,      //取模后输出的终止信号
    output            data_valid     //取模后的数据有效信号
);

//reg define
reg  [47:0] 	source_data;

wire [47:0]     real_square;
wire [47:0]     image_square;


reg  [23:0]  	data_real;			//实部原码
reg  [23:0]  	data_imag;			//虚部原码
reg  [7:0]  	source_valid_d;
reg  [7:0] 	    source_eop_d;
wire [31:0]     data_modulus_med;

reg [31:0]    data_modulus;
//*****************************************************
//**                    main code
//***************************************************** 
//wire [9:0] data_modulus_test;
//assign data_modulus_test = fft_data[31:22]; 

assign fft_data = data_modulus ;

assign  data_eop =source_eop;
//assign  data_eop = source_eop_d[7];

  
// 计数器，用于跟踪需要保持有效的额外时钟周期数  
reg [4:0] counter;  // 使用5位计数器，足以计数到17（2^5-1 = 31）  
reg       source_valid;  

always @(posedge clk ) begin  
    if (!rst_n) begin  
        // 异步复位时，清零计数器和输出  
        counter <= 5'b0;  
        source_valid <= 1'b0;  
    end else begin  
        // 检测到a有效时，启动计数器  
        if (fft_valid) begin  
            counter <= 5'd17;  // 设置为17，或根据需要调整  
            source_valid <= 1'b1; // 立即设置输出为有效  
        end else if (counter > 0) begin  
            // 计数器递减，保持输出有效  
            counter <= counter - 1'b1;  
            source_valid <= 1'b1;  
        end else begin  
            // 计数器到0，输出无效  
            source_valid <= 1'b0;  
        end  
    end  
end  
  


/*
//取实部和虚部的平方和
always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        source_data <= 48'd0;
        data_real   <= 24'd0;
        data_imag   <= 24'd0;
    end
    else begin
        if(source_real[23]==1'b0)               //由补码计算原码
            data_real <= source_real[23:0];
        else
            data_real <= ~source_real[23:0] + 1'b1;
            
        if(source_imag[23]==1'b0)               //由补码计算原码
            data_imag <= source_imag[23:0];
        else
            data_imag <= ~source_imag[23:0] + 1'b1;    
                                                //计算原码平方和
        source_data <= (data_real * data_real) + (data_imag * data_imag);
    end
end
*/

mult_real mult_real (
  .CLK(clk),  // input wire CLK
  .A(source_real),      // input wire A
  .B(source_real),      // input wire B
  .P(real_square)      // output wire P
);

mult_image mult_image (
  .CLK(clk),  // input wire CLK
  .A(source_imag),      // input wire A
  .B(source_imag),      // input wire B
  .P(image_square)      // output wire P
);

//对信号进行打拍延时处理
always @ (posedge clk ) begin
    if(!rst_n || !source_valid) begin // 
        source_data <= 48'd0;
    end
    else begin
        source_data <= image_square + real_square;
    end
end

//对信号进行打拍延时处理
always @ (posedge clk ) begin
    if(!rst_n) begin
        source_eop_d   <= 8'd0;
        source_valid_d <= 8'd0;
    end
    else begin
        source_valid_d <= {source_valid_d[6:0],source_valid};
        source_eop_d   <= {source_eop_d[6:0],source_eop};
    end
end


always @ (posedge clk ) begin
    if(!rst_n) begin
        data_modulus  <= 32'd0;
    end
    else if(data_valid) begin
        data_modulus<=data_modulus_med[31:9];   //2*data_modulus_med/1024
    end
end


//例化cordic模块,开根号运算
cordic_0 u_cordic_0 (
  .aclk(clk),                                        
  .s_axis_cartesian_tvalid(source_valid),  
  .s_axis_cartesian_tdata(source_data),   
  .m_axis_dout_tvalid(data_valid),         
  .m_axis_dout_tdata(data_modulus_med)            
);

endmodule 
