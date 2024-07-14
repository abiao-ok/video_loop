/*==============================================


==============================================*/
module cmos_crop (
    input           clk           ,
    input           rst_n         ,
    input           vs_in         ,
    input           de_in         ,
    input [15:0]    rgb565_in     ,
    output          vs_out        ,
    output reg      de_out        ,
    output reg[15:0]rgb565_out
);
    wire rstn;
    assign rstn = rst_n && ~vs_in;
    
    reg  [10:0] hs		;	// 
    wire 		hs_add	;
    wire 		hs_end	;
    always @(posedge clk or negedge rstn)begin	// 
        if(!rstn)begin
            hs <= 'd0;
        end
        else if(hs_add)begin
            if(hs_end)begin
                hs <= 'd0;
            end
            else begin
                hs <= hs + 1'b1;
            end
        end
    end
    assign hs_add = de_in;
    assign hs_end = hs_add && (hs == 11'd1280 - 1'b1);
    
    reg  [ 9:0] vs		;	// 
    wire 		vs_add	;
    wire 		vs_end	;
    always @(posedge clk or negedge rstn)begin	// 
        if(!rstn)begin
            vs <= 'd0;
        end
        else if(vs_add)begin
            if(vs_end)begin
                vs <= 'd0;
            end
            else begin
                vs <= vs + 1'b1;
            end
        end
    end
    assign vs_add = hs_end;
    assign vs_end = vs_add && (vs == 10'd720 - 1'b1);
    
    reg de_d0, de_d1;
    always @(posedge clk or negedge rstn)begin		//
        if(!rstn)begin
            de_d0 <= 1'b0;
        end
        else if((hs==11'd159) && de_in)begin
            de_d0 <= 1'b1;
        end
        else if((hs==11'd1119) && de_in)begin
            de_d0 <= 1'b0;
        end
    end
    
    always @(posedge clk or negedge rstn)begin		//
        if(!rstn)begin
            de_d1 <= 1'b0;
        end
        else if(vs==10'd90)begin
            de_d1 <= 1'b1;
        end
        else if(vs==10'd630)begin
            de_d1 <= 1'b0;
        end
    end
    
    always @(posedge clk or negedge rstn)begin		//
        if(!rstn)begin
            de_out <= 1'b0;
        end
        else begin
            de_out <= de_d0 && de_d1 && de_in;
        end
    end
    
    assign vs_out = vs_in;
    
    always @(posedge clk or negedge rst_n)begin		//
        if(!rst_n)begin
            rgb565_out <= 16'd0;
        end
        else begin
            rgb565_out <= rgb565_in;
        end
    end
    
endmodule
