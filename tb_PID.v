

module tb_PID (
    input wire          clk         ,             
    input wire          rst_n       ,           
    input wire [31:0]   P_target    , 
    output reg [31:0]   i_current 
);

// 系统参数，使用 Q9.23 位定点数表示
parameter KE = 32'd4194;    // 0.5e - 3 转换
parameter TC = 32'd209715200;       // 
parameter A  = 32'd5670699;    // 0.676 转换为
parameter B  = 32'd0;         // 系数 b
parameter C  = 32'd83886;     // 0.01 转换为 
parameter D  = 32'd0;         // 偏置系数 d

//P_target = 32'd2517;

parameter KP = 32'd41943040;        // 比例增益
parameter KI = 32'd838861;        // 积分增益，由于积分增益较小，可根据实际情况调整
parameter KD = 32'd83886;        // 微分增益，由于微分增益较小，可根据实际情况调整

// 时间步长，使用 23 位定点数表示
//parameter TIME_STEP = 23'd8192; // 0.1 转换为 23 位定点数，
//wire [31:0]   P_target ;
// reg [31:0]   i_current;
// 内部变量
wire [31:0] P;
wire [63:0] P_med1,P_med2;             // 光功率

reg [31:0] error;         // 误差
reg [31:0] integral;      // 积分项
reg [31:0] previous_error; // 上次误差
reg [31:0] derivative;    // 微分项
reg [31:0] control_signal; // PID 输出

// 计算光功率
assign   P_med1 = ((KE * TC) >> 23) + C ;
assign   P_med2 = ((A * i_current) >> 23) + B ;
assign   P = P_med1 * P_med2 >> 23 ;


// PID 控制器逻辑
always @(posedge clk ) begin
    if (!rst_n) begin
        i_current       <= 32'd0;
        error           <= 32'd0;
        integral        <= 32'd0;
        previous_error  <= 32'd0;
        derivative      <= 32'd0;
        control_signal  <= 32'd0;
    end else begin
        // 计算误差
        error <= P_target - P;
        
        // 积分项
        integral <= integral + error;
        
        // 微分项
        derivative <= error - previous_error ;
        
        // PID 输出
        control_signal <= ((KP * error) >> 23) + ((KI * integral) >> 23) + ((KD * derivative) >> 23);
        
        // 调整驱动电流
        i_current <= i_current + control_signal;
        
        // 控制电流的上下限
        if (i_current < 32'd0) begin
            i_current <= 32'd0;
        end else if (i_current > 32'd167772 ) begin // 假设最大电流为 20mA
            i_current <= 32'd167772  ;
        end
        
        // 更新误差
        previous_error <= error;
    end
end

endmodule
