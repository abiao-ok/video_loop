/*==============================================
HDMI: 1920*1080 -> 960*540
    SrcX_width/DstX_width = 2
    SrcX*2 = 4*DstX + 1   
    
过一个 AvgPooling 2x2 s=2 p=0 即可

Total LUTs: 28 of 42800 (0.07%)
	LUTs as dram: 0 of 17000 (0.00%)
	LUTs as logic: 28
Total Registers: 8 of 64200 (0.01%)
==============================================*/
module AvgPooling (
    clk         ,   // input
    pixel_1     ,   // input [ 7:0] (1,1)位置像素
    pixel_2     ,   // input [ 7:0] (1,2)位置像素
    pixel_3     ,   // input [ 7:0] (2,1)位置像素
    pixel_4     ,   // input [ 7:0] (2,2)位置像素
    pout            // output[ 7:0] 结果在下一拍加载
);
    input           clk     ;
    input [ 7:0]    pixel_1 ;
    input [ 7:0]    pixel_2 ;
    input [ 7:0]    pixel_3 ;
    input [ 7:0]    pixel_4 ;
    output reg[ 7:0]pout    ;
    
    wire [8:0] addp1_p2, addp3_p4;
    wire [9:0] pout_d0;
    
    assign addp1_p2 = pixel_1 + pixel_2;
    assign addp3_p4 = pixel_3 + pixel_4;
    assign pout_d0  = addp1_p2 + addp3_p4;
    
    always @(posedge clk)begin		// 除以4
        pout = pout_d0[9:2];
    end
    
endmodule
