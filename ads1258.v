  `timescale 1ns / 1ps
  /*==first:Write REGISTER
    ==Second:Pulse Convert
    ==Thirty:Read REGISTER
  */
  module ads1258 #(parameter Fs_Hz = 1000)
  (
       input                  sysclk            ,
       input                  locked           ,
       input                  Rx_0              ,
       output    reg          Tx_0              ,
       output    reg          Clk_0              ,
       output    reg          CS                ,

       output                   en_Ain0     , 
       //output                   en_Ain1     ,
       output    reg [31:0]   Ain0          
       //output    reg [31:0]   Ain1  
      );
  parameter [4:0] Bit_Num=8       ;
  localparam K_Fs = 28'h2F003A0;
  localparam Num_Cha = 4'd2;
  reg [4:0] spi_reg_c;
  reg          data_32_en;
  reg          data_8_en ;
  reg          CLK_DIV_s ;
  reg          CLK_pp    ;
  /*==�Ĵ�������24��8λ��������һ��Ϊд/������ڶ���Ϊд������ľ���Ĵ���     
                  ����������Ϊ��ѡ���ľ���Ĵ����е���������       */
  wire [7:0] spi_reg [0:23];
  assign spi_reg[0] = 8'h60, spi_reg[1] = 8'h12;
  assign spi_reg[2] = 8'h61, spi_reg[3] = 8'h10;                                              
  assign spi_reg[4] = 8'h62, spi_reg[5] = 8'h00;                                              
  assign spi_reg[6] = 8'h63, spi_reg[7] = 8'h00;                                              
  assign spi_reg[8] = 8'h64, spi_reg[9] = 8'h07;    //4---0-12�̶��˿�����˿ڶ���   07Ϊ�˿�Ain0 Ain1  Ain2           
  assign spi_reg[10]= 8'h65, spi_reg[11]= 8'h00;    //5---12-24������˿ڶ���                        
  assign spi_reg[12]= 8'h66, spi_reg[13]= 8'h00;                                              
  assign spi_reg[14]= 8'h67, spi_reg[15]= 8'hff;                                              
  assign spi_reg[16]= 8'h68, spi_reg[17]= 8'h00;                                              
  assign spi_reg[18]= 8'h80, spi_reg[19]= 8'h30;                                              
  assign spi_reg[20]= 8'hff;                                                                 
  assign spi_reg[21]= 8'hff;                                                                 
  assign spi_reg[22]= 8'hff;                                                                 
  assign spi_reg[23]= 8'hff;                                                                 
  
     
  clk_div #(.Isysclk_Tns(20), .Osysclk_Tns(320)) u_sclk(
      .locked(locked)   ,
      .clk_in(sysclk)   ,              
      .clkout(Sclk)
  );
  
  
  always @(posedge sysclk ) begin
      if (!locked) begin
          CLK_DIV_s <= 0;
      end else begin
          CLK_DIV_s <= Sclk;
      end
  end
  
  always @(posedge sysclk ) begin
      if (!locked) begin
          CLK_pp <= 0;
      end else begin
          if (Sclk == 1 && CLK_DIV_s == 0) begin
              CLK_pp <= 1;
          end else begin
              CLK_pp <= 0;
          end
      end
  end    
  /*==========Write Reg REGISTER=====Write highest bit firstly===*/
  wire  [7:0] Tx_med;
  assign Tx_med = spi_reg[spi_reg_c];
  
  
  reg [3:0] SPI_Write_State ;
  reg [8:0] Send_Num          ;
  reg [7:0] WRITE_CODE,Send_Code        ;
  
  reg [7:0] In_Code_0;
  reg [7:0]     READ_CODE_0       ;
  reg         spi_stop,spi_start        ;
  
  always @(posedge sysclk ) begin
      if (!locked) begin
          SPI_Write_State <= 4'd0;
          Send_Num <= 0;
          CS <= 1'b1;
          Clk_0 <= 1'b0;
          Tx_0 <= 1'b0;
          Send_Code <= 8'b0;
          In_Code_0 <= 8'b0;
          READ_CODE_0 <= 8'b0;
          spi_stop <= 1'b0;
      end 
      else begin
          case (SPI_Write_State)
              0: begin
                  Tx_0 <= 1'b0;
                  spi_stop <= 1'b0;
                  if (spi_start == 1'b1) begin
                      Send_Num <= 0;
                      SPI_Write_State <= 1;
                  end
              end
              1: begin
                  if (CLK_pp == 1'b1) begin
                      Clk_0 <= 1'b0;
                      Send_Code <= WRITE_CODE;
                      SPI_Write_State <= SPI_Write_State + 1;
                  end
              end
              2: begin
                  if (CLK_pp == 1'b1) begin
                      Clk_0 <= 1'b0;
                      Tx_0 <= Send_Code[Bit_Num - 1];   //��д��Ĵ�����ֵ�ɸߵ�����λ����
                      Send_Code <= Send_Code<<1;
                      Send_Num <= Send_Num + 1;
                      SPI_Write_State <= SPI_Write_State + 1;
                      CS <= 1'b0;
                  end
              end
              3: begin
                  if (CLK_pp == 1'b1) begin
                      Clk_0 <= 1'b1;
                      In_Code_0 <= {In_Code_0[Bit_Num - 2:0], Rx_0};           
                      if (Send_Num >= Bit_Num) begin
                          Send_Num <= 0;
                          SPI_Write_State <= SPI_Write_State + 1;
                      end else begin
                          SPI_Write_State <= 2;
                      end
                  end
              end
              4: begin
                  READ_CODE_0 <= In_Code_0;
                  if (CLK_pp == 1'b1) begin
                      Clk_0 <= 1'b0;
                      CS    <= 1'b0;
                      SPI_Write_State <= SPI_Write_State + 1;
                  end
              end
              5: begin
                  Tx_0 <= 1'b0;
                  Clk_0 <= 1'b0;
                  CS <= 1'b0;
                  SPI_Write_State <= 0;
                  spi_stop <= 1'b1;
              end
              default: begin
                  CS <= 1'b1;
                  Clk_0 <= 1'b0;
                  Tx_0 <= 1'b0;
                  Send_Num <= 0;
                  SPI_Write_State <= 0;
              end
          endcase
      end
  end
  
  reg [15:0] delay_c0 ;
  reg [27:0] delay_c1;
  
  always @(posedge sysclk ) begin
      if (!locked) begin
          spi_start <= 1'b0;
          WRITE_CODE <= 8'b0;
          spi_reg_c <= 5'd0;
          delay_c0 <= 16'b0;
          delay_c1 <= 28'b0;
          data_8_en <= 1'b0;
          data_32_en <= 1'b0;
      end else begin
          case (spi_reg_c)
              0: begin
                  if (delay_c0 == 16'hf000) begin
                      spi_start <= 1'b1;
                      WRITE_CODE <= Tx_med;//spi_reg[spi_reg_c];
                      spi_reg_c <= spi_reg_c + 1;
                      delay_c0 <= 16'b0;
                      data_8_en <= 1'b0;
                      data_32_en <= 1'b0;
                  end else begin
                      spi_start <= 1'b0;
                      delay_c0 <= delay_c0 + 1;
                      data_8_en <= 1'b0;
                      data_32_en <= 1'b0;
                  end
              end
              1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 20: begin
                  data_8_en <= 1'b0;
                  data_32_en <= 1'b0;
                  if (spi_stop == 1'b1) begin
                      spi_start <= 1'b1;
                      WRITE_CODE <= Tx_med;//spi_reg[spi_reg_c];
                      spi_reg_c <= spi_reg_c + 1;
                  end else begin
                      spi_start <= 1'b0;
                  end
              end
              19: begin
                  data_8_en <= 1'b0;
                  data_32_en <= 1'b0;                
                  if (delay_c1 == 28'd98568 ) begin     //98568==500HZ-----1HZ==197  K_Fs / Fs_Hz / Num_Cha
                      spi_start <= 1'b1;
                      WRITE_CODE <= Tx_med;//spi_reg[spi_reg_c];
                      spi_reg_c <= spi_reg_c + 1;
                      delay_c1 <= 28'b0;
                  end else begin
                      spi_start <= 1'b0;
                      delay_c1 <= delay_c1 + 1;
                  end
              end
              21, 22, 23: begin
                  data_32_en <= 1'b0;
                  if (spi_stop == 1'b1) begin
                      spi_start <= 1'b1;
                      WRITE_CODE <= Tx_med;//spi_reg[spi_reg_c];
                      spi_reg_c <= spi_reg_c + 1;
                      data_8_en <= 1'b1;
                  end else begin
                      spi_start <= 1'b0;
                      data_8_en <= 1'b0;
                  end
              end
              24: begin
                  if (spi_stop == 1'b1) begin
                      spi_start <= 1'b1;
                      WRITE_CODE <= spi_reg[18];
                      spi_reg_c <= spi_reg_c + 1;
                      data_8_en <= 1'b1;
                 end else begin
                      spi_start <= 1'b0;
                      data_8_en <= 1'b0;
                      data_32_en <= 1'b0;
                  end
              end
              25: begin
                  data_8_en <= 1'b0;
                  spi_reg_c <= 18 + 1;
                  data_32_en <= 1'b1;
              end
              default: begin
                  spi_start <= 1'b0;
                  WRITE_CODE <= 8'b00000000;
                  spi_reg_c <= 5'd0;
                  data_8_en <= 1'b0;
                  data_32_en <= 1'b0;
              end
          endcase
      end
  end
/ // 优化后的代码
/*always @(posedge sysclk) begin
    if (!locked) begin
        CLK_DIV_s <= 0;
    end else begin
        CLK_DIV_s <= Sclk;
    end
end

always @(posedge sysclk) begin
    if (!locked) begin
        CLK_pp <= 0;
    end else begin
        if (Sclk == 1 && CLK_DIV_s == 0) begin
            CLK_pp <= 1;  // 上升沿脉冲生成
        end else begin
            CLK_pp <= 0;
        end
    end
end*/

  //=======����32λ����λ===========
    reg [2:0]  Odata_bit_num;
    reg [0:0]  en_Ain0_med,en_Ain1_med;   
    assign en_Ain0 = en_Ain0_med ;
    assign en_Ain1 = en_Ain1_med ;
 always @(posedge sysclk ) begin
      if (!locked) begin
           Ain0 <= 32'b0   ;
           en_Ain0_med <= 1'b0;
           en_Ain1_med <= 1'b0;
           Odata_bit_num<=3'b000;
      end
      else if(data_8_en==1) begin  
           case (Odata_bit_num)
              3'b000: begin
                  Ain0 <= {READ_CODE_0,24'b0};
                  Odata_bit_num<=3'b001;
                 end
              3'b001:begin
                  Ain0 <= {Ain0[31:24],READ_CODE_0,16'b0};
                  Odata_bit_num<=3'b011;
                end  
              3'b011:begin
                  Ain0 <= {Ain0[31:16],READ_CODE_0,8'b0};
                  Odata_bit_num<=3'b010;
                end 
              3'b010:begin
                  Ain0 <= {Ain0[31:8],READ_CODE_0};
                  en_Ain0_med <= 1'b1 ;
                  Odata_bit_num<=3'b000;
                end
              /*3'b110: begin
                  Ain1 <= {READ_CODE_0,24'b0};
                  Odata_bit_num<=3'b111;
                 end
              3'b111:begin
                  Ain1 <= {Ain1[31:24],READ_CODE_0,16'b0};
                  Odata_bit_num<=3'b101;
                end  
              3'b101:begin
                  Ain1 <= {Ain1[31:16],READ_CODE_0,8'b0};
                  Odata_bit_num<=3'b100;
                end 
              3'b100:begin
                  Ain1 <= {Ain1[31:8],READ_CODE_0};
                  en_Ain1_med <= 1'b1 ;
                  Odata_bit_num<=3'b000;
                end*/
              default: ;
          endcase  
     end
     else begin
        en_Ain0_med <= 1'b0 ;
        en_Ain1_med <= 1'b0 ;
     end
                
  end
  
/*  reg [2:0]  Odata_bit_num;
  always @(posedge sysclk or negedge locked) begin
      if (!locked) begin
          Odata_bit_num   <=  0;
      end
      else if(data_8_en==1) begin 
              if(Odata_bit_num != 4) begin                 //data_8_en:    ___--__--__--__--______--__--__--
                Odata_bit_num   <=  Odata_bit_num + 1;     //Odata_bit_num:-0--1---2---3--4-------1---
              end 
              else begin
                Odata_bit_num  <=   1;
              end
          end
          else Odata_bit_num <=Odata_bit_num;
  end
  
//  reg [31:0] Ain0;
  always @(posedge sysclk or negedge locked) begin
      if (!locked) begin
          Ain0 <= 32'b0   ;
      end
      else begin
          case (Odata_bit_num)
              1: begin
                  Ain0 <= {READ_CODE_0,24'b0};
                 end
              2:begin
                  Ain0 <= {Ain0[31:24],READ_CODE_0,16'b0};
                end  
              3:begin
                  Ain0 <= {Ain0[31:16],READ_CODE_0,8'b0};
                end 
              4:begin
                  Ain0 <= {Ain0[31:8],READ_CODE_0};
                end
              default: ;
          endcase
       end
  end*/
  
 /*
  //����˿�ʱ����data_32_en�仯��ֵ��ֵ����Ӧ�˿�
  reg         [4:0]  Odata_Channel;
  parameter         Channel_num  =    1;
  always @(posedge sysclk or negedge locked) begin
      if (!locked) begin
          Odata_Channel   <=  0;
      end
      else if(data_32_en==1) begin 
              if(Odata_Channel != Channel_num) begin      
                Odata_Channel   <=  Odata_Channel + 1;    
              end 
              else begin
                Odata_Channel  <=  0 ;
              end
      end 
      else  Odata_Channel  <=  0;                      
  end
  
//reg [23:0] Ain01     ;
reg [31:0] Ain01     ;
  always @(posedge sysclk or negedge locked) begin
      if (!locked) 
          Ain01 <= 32'b0   ;
      else begin
          case (Odata_Channel)
              1: begin
                  //Ain01 <= Ain0[23:0];
                  ch1_reg <= Ain0[31:0];
                 end
              2:begin
                  Ain01 <= Ain0;
                end  
              3:begin
                  Ain02 <= Ain0;
                end 
              4:begin
                  Ain03 <= Ain0;
                end
              
              default: ;
          endcase
       end
  end
  */
//AD ��ѹ����

/*always @(posedge sysclk)
begin
  if(!locked) begin   
    //Ain01 <= 24'b0   ;
    Ain01 <= 32'b0   ;
  end
  else begin
    //////////CH1����/////////////
    if(Ain01[23]==1'b1) begin                      //����Ǹ���ѹ
	    Ain01[23:0]<=24'hffffff-Ain01+1'b1;
		ch1_sig <= 45;                                //'-' asic��
	 end	 
	 else begin
        ch1_reg<=Ain01;
		ch1_sig<=43   ;                                  //'+' asic��		 
	 end
	end	 
end 		 
*/      
endmodule
