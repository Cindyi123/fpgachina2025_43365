`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/13 10:11:41
// Design Name: 
// Module Name: PID_UV_LED
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module PID_UV_LED(
    input wire          clk         ,             
    input wire          rst_n       , 
    input wire [31:0]   P_measure           ,       
    input wire [31:0]   P_target    , 
    output reg [31:0]   i_current 
);



//P_target = 32'd2517;

parameter KP = 32'd41943040;        // ��������
parameter KI = 32'd838861;        // �������棬���ڻ��������С���ɸ���ʵ���������
parameter KD = 32'd83886;        // ΢�����棬����΢�������С���ɸ���ʵ���������

// ʱ�䲽����ʹ�� 23 λ��������ʾ
//parameter TIME_STEP = 23'd8192; // 0.1 ת��Ϊ 23 λ��������

// �ڲ�����

reg [31:0] error;         // ���
reg [31:0] integral;      // ������
reg [31:0] previous_error; // �ϴ����
reg [31:0] derivative;    // ΢����
reg [31:0] control_signal; // PID ���



// PID �������߼�
always @(posedge clk ) begin
    if (!rst_n) begin
        i_current       <= 32'd0;
        error           <= 32'd0;
        integral        <= 32'd0;
        previous_error  <= 32'd0;
        derivative      <= 32'd0;
        control_signal  <= 32'd0;
    end else begin
        // �������
        error <= P_target - P_measure;
        
        // ������
        integral <= integral + error;
        
        // ΢����
        derivative <= error - previous_error ;
        
        // PID ���
        control_signal <= ((KP * error) >> 23) + ((KI * integral) >> 23) + ((KD * derivative) >> 23);
        
        // ������������
        i_current <= i_current + control_signal;
        
        // ���Ƶ�����������
        if (i_current < 32'd0) begin
            i_current <= 32'd0;
        end else if (i_current > 32'd167772 ) begin // ����������Ϊ 20mA
            i_current <= 32'd167772  ;
        end
        
        // �������
        previous_error <= error;
    end
end

endmodule
