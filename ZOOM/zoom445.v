/*==============================================


==============================================*/
module zoom445 (    // dx,dy 4bit; p 5bit
    clk         ,   // input
    dx_in       ,   // input [ 3:0] 系数 dx
    dy_in       ,   // input [ 3:0] 系数 dy
    dx_dy       ,   // input [ 7:0] dx*dy   会在 dy_in 有效的第二拍有效
    pixel_1     ,   // input [ 4:0] (1,1)位置像素
    pixel_2     ,   // input [ 4:0] (1,2)位置像素
    pixel_3     ,   // input [ 4:0] (2,1)位置像素
    pixel_4     ,   // input [ 4:0] (2,2)位置像素
    pout            // output[ 4:0] 缩放后的像素 第五拍输出
);
    input           clk     ;
    input [ 3:0]    dy_in   ;
    input [ 3:0]    dx_in   ;
    input [ 7:0]    dx_dy   ;
    input [ 4:0]    pixel_1 ;
    input [ 4:0]    pixel_2 ;
    input [ 4:0]    pixel_3 ;
    input [ 4:0]    pixel_4 ;
    output reg[ 4:0]pout    ;
    
    wire [ 5:0] sub21   ;
    // (p2 - p1) 在第一拍加载
    sub_source #(.width(5))p2_p1(    // c=a-b     
        .clk (clk       )   ,   // input
        .a   (pixel_2   )   ,   // input [4:0] unsigned
        .b   (pixel_1   )   ,   // input [4:0] unsigned
        .c   (sub21     )       // output[5:0] 打拍输出 最高位符号位 源码
    );
    
    wire [ 5:0] sub31   ;
    // (p3 - p1) 在第一拍加载
    sub_source #(.width(5))p3_p1(    // c=a-b     
        .clk (clk       )   ,   // input
        .a   (pixel_3   )   ,   // input [4:0] unsigned
        .b   (pixel_1   )   ,   // input [4:0] unsigned
        .c   (sub31     )       // output[5:0] 打拍输出 最高位符号位 源码
    );
    
    reg  [ 3:0] dx, dy  ;
    // 把用得到的参数放到第一拍
    always @(posedge clk)begin		//
        dy <= dy_in;
        dx <= dx_in;
    end
    
    wire [ 8:0] mul21_dx;
    // (p2-p1)*dx 在第三拍加载
    mul5x4 p2p1_dx(
        .clk (clk       )   ,  // input        
        .a   (sub21[4:0])   ,  // input [ 4:0] unsigned 可连续输入
        .b   (dx        )   ,  // input [ 3:0] unsigned
        .c   (mul21_dx  )      // output[ 8:0] unsigned 输出隔了一拍对应输入
    );
    
    wire [ 8:0] mul31_dy;
    //  (p3-p1)*dy 在第三拍加载
    mul5x4 p3p1_dy(
        .clk (clk       )   ,  // input        
        .a   (sub31[4:0])   ,  // input [ 4:0] unsigned 可连续输入
        .b   (dy        )   ,  // input [ 3:0] unsigned
        .c   (mul31_dy  )      // output[ 8:0] unsigned 输出隔了一拍对应输入
    );
    
    reg  mul21_dx_si, mul21_dx_sign, mul31_dy_si, mul31_dy_sign;
    // 把(p2-p1), (p3-p1)的正负性放到第三拍
    always @(posedge clk)begin		//
        mul21_dx_si   <= sub21[5];
        mul21_dx_sign <= mul21_dx_si;
        mul31_dy_si   <= sub31[5];
        mul31_dy_sign <= mul31_dy_si;
    end
    
    wire [8:0] p2p1dx, p3p1dy;
    // 把 (p2-p1)*dx, (p3-p1)*dy 加上低4位dy和符号位 扩充为15位的补码(源码->补码)在第三拍
    // 源码: {mul21_dx_sign,1'b0, mul21_dx, 4'b0};
    assign p2p1dx = mul21_dx_sign?(~mul21_dx):mul21_dx;
    assign p3p1dy = mul31_dy_sign?(~mul31_dy):mul31_dy;
    
    reg [ 4:0]  p1_d1, p1_d2, p1_d3;
    // 把p1加载到第三拍 p1是正 本身即补码
    always @(posedge clk)begin		// 
        p1_d1 <= pixel_1;
        p1_d2 <= p1_d1;
        p1_d3 <= p1_d2;
    end
    
    
    wire [10:0] add1_2_comple_4;    // 缺了低4位0
    reg  [10:0] add12_3_comple_4/* synthesis syn_preserve = 1 */;   // 缺了低4位0
    // 第三拍补码计算 p1 + (p2-p1)*dx 
    assign add1_2_comple_4  = {2'b0, p1_d3, 4'b0} + {mul21_dx_sign, mul21_dx_sign, p2p1dx} + mul21_dx_sign;
    
    // 补码计算 (p1 + (p2-p1)*dx) + (p3-p1)*dy 放在第四拍
    always @(posedge clk)begin		//
        add12_3_comple_4 = add1_2_comple_4 + {mul31_dy_sign, mul31_dy_sign, p3p1dy} + mul31_dy_sign;
    end
    
    reg  [ 5:0] add41, add32;
    // p4+p1 和 p3+p2 加载在第一拍
    always @(posedge clk)begin
        add41 <= pixel_4 + pixel_1;
        add32 <= pixel_3 + pixel_2;
    end
    
    wire [ 6:0] sub42   ;
    // (p4+p1) - (p3+p2) 数据在第二拍加载
    sub_source #(.width(6)) sub_b4_3(    // c=a-b     
        .clk (clk   )   ,   // input
        .a   (add41 )   ,   // input [5:0] unsigned
        .b   (add32 )   ,   // input [5:0] unsigned
        .c   (sub42 )       // output[6:0] 打拍输出 最高位符号位 源码
    );
    
    // dx * dy (8bit)在第二拍加载 
    wire [13:0] mul42_dxy/* synthesis syn_keep=1 */;
    // ((p4+p1) - (p3+p2)) * dx*dy 在第四拍加载
    mul6x8 mul6x8_mul42b_dxdy(
        .clk (clk       ),   // input        
        .a   (sub42[5:0]),   // input [ 5:0] unsigned 可连续输入
        .b   (dx_dy     ),   // input [ 7:0] unsigned
        .c   (mul42_dxy )    // output[13:0] unsigned 输出隔了一拍对应输入
    );
    
    reg  mul42_dxy_si, mul42_dxy_sign   ;
    // 把 (p4+p1)-(p3+p2) 的正负性加载到第四拍
    always @(posedge clk)begin		//
        mul42_dxy_si   <= sub42[6];
        mul42_dxy_sign <= mul42_dxy_si;
    end
    
    wire [13:0] p42dxy;
    // 把 ((p4+p1)-(p3+p2))*dx*dy 加符号位扩充为15位的补码 在第四拍
    assign p42dxy = mul42_dxy_sign?(~mul42_dxy):mul42_dxy;
    
    wire [14:0] pout_comple/* synthesis syn_keep=1 */;
    // 第四拍计算结果
    assign pout_comple = {add12_3_comple_4, 4'b0} + {mul42_dxy_sign, p42dxy} + mul42_dxy_sign;
    
    // 第五拍输出
    always @(posedge clk)begin		// 
        pout <= pout_comple[12:8];
    end
    
    
endmodule
