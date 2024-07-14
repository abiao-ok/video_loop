/*==============================================
Total LUTs: 154 of 42800 (0.36%)
	LUTs as dram: 0 of 17000 (0.00%)
	LUTs as logic: 154
Total Registers: 45 of 64200 (0.07%)
Fmax = Mhz
==============================================*/
// 测试用
// module mul7x8 ( // unsigned
    // clk ,   // input        at next T
    // a_d0   ,   // input [ 6:0] unsigned
    // b_d0   ,   // input [ 7:0] unsigned
    // c        // output[13:0] unsigned
// );
    // input           clk;
    // input [ 6:0]    a_d0;
    // input [ 7:0]    b_d0;
    // output reg[13:0]c ;
    
    // reg [ 6:0]a;
    // reg [ 7:0]b;
    // always @(posedge clk)begin		//
        // a <= a_d0;
        // b <= b_d0;
    // end

module mul7x8 ( // c = a * b
    clk ,   // input        
    a   ,   // input [ 6:0] unsigned 可连续输入
    b   ,   // input [ 7:0] unsigned
    c       // output[14:0] unsigned 输出隔了一拍对应输入
);
    input           clk;
    input [ 6:0]    a;
    input [ 7:0]    b;
    output reg[14:0]c/* synthesis syn_preserve = 1 */;
    
    wire [ 6:0] d_d30, d_d1;
    wire [ 7:0] d_d4, d_d20;
    wire [10:0] d_d3;
    wire [10:0] d_d2;
    wire [11:0] c_2;
    wire [14:0] c_1;
    
    // c = (a[6:3]*8 + a[2:0]) * (b[7:4]*16 + b[3:0])
    
    // {a[6:3] * b[7:4], 7'b0}
    mul4x4 mul4x4_d4(.clk(clk), .a(a[6:3]), .b(b[7:4]), .c(d_d4));
    
    // {a[2:0] * b[7:4], 4'b0}
    mul3x4 mul3x4_d3(.clk(clk), .a(a[2:0]), .b(b[7:4]), .c(d_d30));
    assign d_d3 = {d_d30, 4'b0};
    
    // {a[6:3] * b[3:0], 3'b0}
    mul4x4 mul4x4_d2(.clk(clk), .a(a[6:3]), .b(b[3:0]), .c(d_d20));
    assign d_d2 = {d_d20, 3'b0};
    
    // {a[2:0] * b[3:0]}
    mul3x4 mul3x4_d1(.clk(clk), .a(a[2:0]), .b(b[3:0]), .c(d_d1));
    
    assign c_2 = d_d3 + d_d2;
    assign c_1 = {d_d4,d_d1};
    
    always @(posedge clk)begin
        c <= c_2 + c_1;
    end
    
endmodule

