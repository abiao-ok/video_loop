module data_gen(
    input                   clk     ,//时钟信号
    input                   rst_n   ,//复位信号

    input       [11:0]      h_addr  ,//数据有效显示区域地址
    input       [11:0]      v_addr  ,//数据有效显示区域地址
    
    output  reg [23:0]      data_disp        
);
//参数定义
    parameter   BLACK       = 24'h000000,
                RED         = 24'hFF0000,
                GREEN       = 24'h00FF00,
                BLUE        = 24'h0000FF,
                YELLOW      = 24'hFFFF00,
                SKY_BULE    = 24'h00FFFF,
                PURPLE      = 24'hFF00FF,
                GREY        = 24'hC0C0C0,
                WIGHT       = 24'hFFFFFF;

    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            data_disp <= BLACK;
        end
        else begin
            case({h_addr[10], h_addr[9], h_addr[8]})
                3'd0: data_disp <= RED;         // 红
                3'd1: data_disp <= GREEN;       // 绿
                3'd2: data_disp <= BLUE;        // 蓝
                3'd3: data_disp <= YELLOW;      // 黄
                3'd4: data_disp <= SKY_BULE;    // 天蓝
                3'd5: data_disp <= PURPLE;      // 紫
                3'd6: data_disp <= GREY;        // 灰
                3'd7: data_disp <= WIGHT;       // 白
                default:data_disp <= data_disp;
            endcase
        end
    end


endmodule

