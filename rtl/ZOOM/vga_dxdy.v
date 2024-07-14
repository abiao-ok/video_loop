/*==============================================
摄像头: 1280*720 -> 960*540
    通过matlab计算 
    
    x=[0:959];
    y=((x+0.5).*4)./3 - 0.5;
    a=floor(y);
    b=y-a;
    c=b*32;
    d=floor(c);
    
    发现规律：
    x 坐标从零开始连续三个，间隔一个: 0,1,2, 4,5,6, 8,9,10, 12,.......
    不需要比对坐标，只需要依附2x2矩阵即可
    
    dx:小数位乘以32后 5.33, 16, 26.67不断循环
    取: 6, 16, 26 -> 3, 8, 13
    向靠近中心点的方式取舍, 而不是四舍五入，精度略有损失
    但减小了位宽 变成4bit数, 进一步节约资源
    
    地址的低两位对应系数
    循化输出 3, 8, 13, 0
    
==============================================*/
module vga_dxdy (
    clk         ,   // input        
    vga_x       ,   // input [ 1:0] 根据 x 坐标 计算系数
    vga_y       ,   // input [ 1:0] 根据 y 坐标
    vga_dx      ,   // output[ 3:0] 系数 组合逻辑 没有打拍
    vga_dy      ,   // output[ 3:0] 系数
    vga_dxy         // output[ 7:0] 系数 在vga_dx有效的后面第二拍有效
);
    input           clk     ;
    input     [ 1:0]vga_x   ;
    input     [ 1:0]vga_y   ;
    output reg[ 3:0]vga_dx  ;
    output reg[ 3:0]vga_dy  ;
    output reg[ 7:0]vga_dxy ;
    
    always @(*)begin	// 
        case(vga_x)
            2'd0:vga_dx = 4'd0;
            2'd1:vga_dx = 4'd3;
            2'd2:vga_dx = 4'd8;
            2'd3:vga_dx = 4'd13;
            default:vga_dx = 4'd0;
        endcase
    end
    
    always @(*)begin	// 
        case(vga_y)
            2'd0:vga_dy = 4'd3 ;
            2'd1:vga_dy = 4'd8 ;
            2'd2:vga_dy = 4'd13;
            2'd3:vga_dy = 4'd0;
            default:vga_dy = 4'd0;
        endcase
    end
    
    wire [ 7:0]dx_dy_0;
    mul4x4 mul4x4(
        .clk(clk    ) ,   // input        
        .a  (vga_dx ) ,   // input [ 3:0] unsigned 可连续输入
        .b  (vga_dy ) ,   // input [ 3:0] unsigned
        .c  (dx_dy_0)     // output[ 7:0] unsigned 下一拍输出
    );

    always @(posedge clk)begin		//
        vga_dxy <= dx_dy_0;
    end
    
endmodule

/*==============================================
摄像头: 1280*720 -> 960*540
    SrcX_width/DstX_width = 4/3
    SrcX*32 = 4*(32*DstX + 4)/3
    令 Z_x = {DstX,5'd4}, 共 15bit, 最大值：15'd30724
    则 4*Z_x/3 = 4*Z_x/(4*(1 - 2^-2)) = Z_x*(1 + 2^-2)*(1 + 2^-4)*(1 + 2^-8)*.....
    
    取 SrcX*32 = Z_x*(1 + 2^-2)*(1 + 2^-4)*(1 + 2^-8)*(1 + 2^-16)
    过程为: 
    Z_x[14:0] = {DstX,5'd4}
    A_x[15:0] = Z_x[14:0] + Z_x[14:2]  考虑进位: 30724+30724/4   = 16'd38405 会进位
    B_x[15:0] = A_x[15:0] + A_x[15:4]  考虑进位: 38405+38405/16  = 16'd40805 不会进位
    C_x[15:0] = B_x[15:0] + B_x[15:8]  考虑进位: 40805+40805/256 = 16'd40964 不会进位
    D_x[15:0] = C_x[15:0]            舍弃，只前需要三步
    高11位整数，第5位小数
    
    同理 Z_y A_y [14:0] 高10位整数，第5位小数
==============================================*/
/* module vga_dxdy (// 摄像头系数，坐标产生模块
    clk         ,   // input        
    rst_n       ,   // input        应该每完成一张图片复位一次
    vga_work    ,   // input        控制进行系数计算, 应该在存参数的fifo有空余才拉高, 拉高则会一直给计算结果
    vga_vld     ,   // output       数据有效信号 与 x,y,dx,dx 同步输出
    vga_x       ,   // output[10:0] 与系数匹配的左上角像素点 x 坐标
    vga_y       ,   // output[ 9:0] 与系数匹配的左上角像素点 y 坐标
    vga_dx      ,   // output[ 4:0] 系数
    vga_dy          // output[ 4:0] 系数
);
    input           clk     ;
    input           rst_n   ;
    input           vga_work;
    output reg      vga_vld ;
    output reg[10:0]vga_x   ;
    output reg[ 9:0]vga_y   ;
    output reg[ 4:0]vga_dx  ;
    output reg[ 4:0]vga_dy  ;
    
    reg  [ 9:0] dstx		;	// 
    wire 		dstx_add	;
    wire 		dstx_end	;
    always @(posedge clk or negedge rst_n)begin	// 
        if(!rst_n)begin
            dstx <= 10'd0;
        end
        else if(dstx_add)begin
            if(dstx_end)begin
                dstx <= 10'd0;
            end
            else begin
                dstx <= dstx + 1'b1;
            end
        end
    end
    assign dstx_add = vga_work;
    assign dstx_end = dstx_add && (dstx == 10'd960 - 1'b1);
    
    reg  [ 9:0] dsty		;	// 
    wire 		dsty_add	;
    wire 		dsty_end	;
    always @(posedge clk or negedge rst_n)begin	// 
        if(!rst_n)begin
            dsty <= 10'd0;
        end
        else if(dsty_add)begin
            if(dsty_end)begin
                dsty <= 10'd0;
            end
            else begin
                dsty <= dsty + 1'b1;
            end
        end
    end
    assign dsty_add = dstx_end;
    assign dsty_end = dsty_add && (dsty == 10'd540 - 1'b1);
    
    wire  [14:0] Z_x, Z_y, A_y, B_y, C_y;
    wire  [15:0] A_x, B_x, C_x;
    assign Z_x[14:0] = {dstx,5'd4};
    assign A_x[15:0] = Z_x[14:0] + Z_x[14:2];
    assign B_x[15:0] = A_x[15:0] + A_x[15:4];
    assign C_x[15:0] = B_x[15:0] + B_x[15:8];
    
    assign Z_y[14:0] = {dsty,5'd4};
    assign A_y[14:0] = Z_y[14:0] + Z_y[14:2];
    assign B_y[14:0] = A_y[14:0] + A_y[14:4];
    assign C_y[14:0] = B_y[14:0] + B_y[14:8];
    
    always @(posedge clk or negedge rst_n)begin		//
        if(!rst_n)begin
            vga_x  <= 11'd0;
            vga_y  <= 10'd0;
            vga_dx <= 5'd0;
            vga_dy <= 5'd0;
            vga_vld<= 1'b0;
        end
        else begin
            vga_x  <= C_x[15:5];
            vga_y  <= C_y[14:5];
            vga_dx <= C_x[ 4:0];
            vga_dy <= C_y[ 4:0];
            vga_vld<= vga_work;
        end
    end
    
endmodule
 */