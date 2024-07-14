/*==============================================
摄像头: 1280*960 -> 720*540   DstX = 0~719
    SrcX_width/DstX_width = 960/540 = 32/18
    SrcX*18 = 32*DstX + 7 = {DstX,5'7}
    令 Z_x = {DstX,5'7}, 共 15bit
    
    SrcX = Z_x*(1 + 2^-3)*(1 + 2^-6)*(1 + 2^-12)*(1 + 2^-24)/16
    过程为: 
    Z_x[15:0] = {DstX,5'd7}            最大值 23047
    A_x[15:0] = Z_x[15:0] + Z_x[15:3]  考虑进位: 23047+23047/8    = 15'd25927 不会进位
    B_x[15:0] = A_x[15:0] + A_x[15:6]  考虑进位: 25927+25927/64   = 16'd26332 不会进位
    C_x[15:0] = B_x[15:0] + B_x[15:12] 考虑进位: 26332+26332/4096 = 16'd26338 不会进位
    D_x[15:0] = C_x[15:0]              舍弃，只前需要三步
    高11位整数，低5位小数
    
    同理 Z_y A_y [14:0] 高10位整数，第5位小数
==============================================*/
module udp_dxdy (
    input               clk     ,   // input        
    input               udp_vs  ,   // input
    input               udp_vld ,   // input 
    input               hs_end  ,   // input        选择系数
    output reg  [ 3:0]  udp_dx  ,   // output[ 3:0] 系数 组合 没有打拍
    output reg  [ 3:0]  udp_dy  ,   // output[ 3:0] 系数 
    output      [ 7:0]  udp_dxy ,   // output[ 7:0] 系数 在vga_dx有效的后面第二拍有效
    output reg          XY_vld      // output
);
    reg [3:0] cntx16, cnty16,udp_dx_0, udp_dy_0;
    always @(posedge clk)begin		//
        if(udp_vs)begin
            cntx16 <= 4'b0;
        end
        else if(udp_vld)begin
            cntx16 <= cntx16 + 1'b1;
        end
    end
    
    always @(posedge clk)begin		//
        if(udp_vs)begin
            cnty16 <= 4'b0;
        end
        else if(hs_end)begin
            cnty16 <= cnty16 + 1'b1;
        end
    end
    
    always @(*)begin		//
        case(cntx16)
            4'd0 :udp_dx = 4'd6 ;
            4'd2 :udp_dx = 4'd3 ;
            4'd3 :udp_dx = 4'd15;
            4'd5 :udp_dx = 4'd12;
            4'd7 :udp_dx = 4'd8 ;
            4'd9 :udp_dx = 4'd4 ;
            4'd11:udp_dx = 4'd1 ;
            4'd12:udp_dx = 4'd13;
            4'd14:udp_dx = 4'd10;
            default:udp_dx = 4'd0;
        endcase
        case(cnty16)
            4'd0 :udp_dy = 4'd6 ;
            4'd2 :udp_dy = 4'd3 ;
            4'd3 :udp_dy = 4'd15;
            4'd5 :udp_dy = 4'd12;
            4'd7 :udp_dy = 4'd8 ;
            4'd9 :udp_dy = 4'd4 ;
            4'd11:udp_dy = 4'd1 ;
            4'd12:udp_dy = 4'd13;
            4'd14:udp_dy = 4'd10;
            default:udp_dy = 4'd0;
        endcase
    end
    
    reg udp_x, udp_y, udp_x_0, udp_y_0;
    always @(*)begin		//
        case(cntx16)
            4'd0 :udp_x = 1'b1;
            4'd2 :udp_x = 1'b1;
            4'd3 :udp_x = 1'b1;
            4'd5 :udp_x = 1'b1;
            4'd7 :udp_x = 1'b1;
            4'd9 :udp_x = 1'b1;
            4'd11:udp_x = 1'b1;
            4'd12:udp_x = 1'b1;
            4'd14:udp_x = 1'b1;
            default:udp_x = 1'b0;
        endcase
        case(cnty16)
            4'd0 :udp_y = 1'b1;
            4'd2 :udp_y = 1'b1;
            4'd3 :udp_y = 1'b1;
            4'd5 :udp_y = 1'b1;
            4'd7 :udp_y = 1'b1;
            4'd9 :udp_y = 1'b1;
            4'd11:udp_y = 1'b1;
            4'd12:udp_y = 1'b1;
            4'd14:udp_y = 1'b1;
            default:udp_y = 1'b0;
        endcase
    end
    
    always @(posedge clk)begin		//
        udp_dx_0 <= udp_dx;
        udp_dy_0 <= udp_dy;
        udp_x_0  <= udp_x ;
        udp_y_0  <= udp_y ;
    end
    
    wire [ 7:0]dx_dy_0;
    mul4x4 mul4x4(
        .clk(clk     ) ,   // input        
        .a  (udp_dx_0) ,   // input [ 3:0] unsigned 可连续输入
        .b  (udp_dy_0) ,   // input [ 3:0] unsigned
        .c  (udp_dxy )     // output[ 7:0] unsigned 下一拍输出
    );
    
    always @(posedge clk)begin		//
        XY_vld <= udp_x_0 && udp_y_0;
    end
    
endmodule
