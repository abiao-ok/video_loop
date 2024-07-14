/*==============================================
两个8bit正数以补码的形式作减法 a-b 输出源码
sub sub_d (minuend, subtrahend, outcome);
#(.width(8))
==============================================*/
module sub_source (    // c=a-b     
    clk     ,   // input
    a       ,   // input [7:0] unsigned
    b       ,   // input [7:0] unsigned
    c           // output[8:0] 打拍输出 unsigned
);
    parameter   width = 8;
    input           clk     ;
    input     [width-1:0] a       ;
    input     [width-1:0] b       ;
    
    // 输出在下一拍加载
    // 两个正数以补码的形式作减法 a-b
    
    // input           rst_n   ;
    // output reg [width:0] c;
    // wire [width:0] positive    ;
    // assign positive = a + {1'b1,~b} + 1'b1; // 结果的补码  最高位判断正负 低8位当做正数
    // always @(posedge clk)begin
        // c <= positive;
    // end
    
    wire [width:0] c_d0   ;
    wire [width-1:0] c_d1   ;
    output reg[width:0] c       ;
    assign c_d0 = a + {1'b1,~b} + 1'b1; // 结果的补码  最高位判断正负 低8位当做正数
    assign c_d1 = a + ~b;
    always @(posedge clk)begin	// 
        if(c_d0[width])
            c = {c_d0[width],~c_d1[width-1:0]};
        else
            c = c_d0;
    end
    
    
endmodule
