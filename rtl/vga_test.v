/*==============================================


==============================================*/
module vga_test (
    clk     ,   // input       
    rst_n   ,   // input       
    vs_out  ,   // output      
    hs_out  ,   // output      
    de_out  ,   // output      
    pout    ,   // output[15:0]
    de_re       // output      
);
    input       clk       ;   //时钟信号
    input       rst_n     ;   //复位信号
    output      vs_out    ;
    output      hs_out    ;
    output      de_out    ;
    output[15:0]pout      ;
    output      de_re     ;
    
    wire [11:0] x_act     ;
    wire [11:0] y_act     ;
    wire[23:0] data_disp  ;
    
    sync_vg # (
        .X_BITS(12),
        .Y_BITS(12),
        .V_TOTAL(12'd750),
        .V_FP(12'd5),
        .V_BP(12'd20),
        .V_SYNC(12'd5),
        .V_ACT(12'd720),
        .H_TOTAL(12'd1650),
        .H_FP(12'd110),
        .H_BP(12'd220),
        .H_SYNC(12'd40),
        .H_ACT(12'd1280),
        .HV_OFFSET(12'd0)
    ) 
    MODE_720p(
        .clk   (clk   ) ,
        .rstn  (rst_n ) ,
        .vs_out(vs_out) ,
        .hs_out(hs_out) ,
        .de_out(de_out) ,
        .de_re (de_re ) ,
        .x_act (x_act ) ,
        .y_act (y_act )
    );

    data_gen data_gen(
        .clk      (clk      ),
        .rst_n    (rst_n    ),
        .h_addr   (x_act    ),
        .v_addr   (y_act    ),
        .data_disp(data_disp)
    );
    
    assign pout = {data_disp[23:19],data_disp[15:10],data_disp[7:3]};
    
    
    
endmodule
