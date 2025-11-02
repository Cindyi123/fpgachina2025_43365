`timescale 1ns / 1ps

module clk_div #(parameter Isysclk_Tns =20 , Osysclk_Tns=200)
(
    input       locked   ,
    input       clk_in ,              
    output reg clkout 
);
        
reg [4:0] cnt;
localparam bps_tx_low=Osysclk_Tns/Isysclk_Tns/2;
localparam bps_tx_hig=Osysclk_Tns/Isysclk_Tns;

always @(posedge clk_in or negedge locked) begin
  if(!locked) begin
    clkout  <=0;
    cnt     <=5'd0;
  end 
  else if(cnt == bps_tx_low-1)
  begin
    clkout <= ~clkout;
    cnt <=5'd0;
  end
  else begin
    cnt <= cnt + 5'd1;
    clkout <= clkout;
  end
end

endmodule

