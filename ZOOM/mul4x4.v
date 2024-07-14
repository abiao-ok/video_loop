// mod
/*==============================================


==============================================*/
// 测试用
// module mul4x4 ( // unsigned
    // clk ,   // input        at next T
    // a_d0   ,   // input [ 3:0] unsigned
    // b_d0   ,   // input [ 3:0] unsigned
    // c        // output[ 7:0] unsigned
// );
    // input           clk;
    // input [ 3:0]    a_d0;
    // input [ 3:0]    b_d0;
    // output reg[ 7:0]c ;
    // wire z7,z6,z5,z4,z3,z2,z1,z0;
    
    // reg [ 3:0]a,b;
    // always @(posedge clk)begin		//
        // a <= a_d0;
        // b <= b_d0;
    // end

module mul4x4 ( // unsigned
    clk ,   // input        at next T
    a   ,   // input [ 3:0] unsigned
    b   ,   // input [ 3:0] unsigned
    c       // output[ 7:0] unsigned
);
    input           clk;
    input [ 3:0]    a;
    input [ 3:0]    b;
    output reg[ 7:0]c;
    wire z7,z6,z5,z4,z3,z2,z1,z0;
    
    GTP_LUT8#(.INIT(256'hFE00_FC00_FC00_F800_F000_E000_8000_0000_0000_0000_0000_0000_0000_0000_0000_0000))
    bit7(.Z(z7),.I7(a[3]),.I6(a[2]),.I5(a[1]),.I4(a[0]),.I3(b[3]),.I2(b[2]),.I1(b[1]),.I0(b[0]));
    
    GTP_LUT8#(.INIT(256'hE1E0_C3E0_83E0_07C0_0FC0_1F80_7F00_FF00_FC00_F800_E000_0000_0000_0000_0000_0000))
    bit6(.Z(z6),.I7(a[3]),.I6(a[2]),.I5(a[1]),.I4(a[0]),.I3(b[3]),.I2(b[2]),.I1(b[1]),.I0(b[0]));
    
    GTP_LUT8#(.INIT(256'h9998_3398_6318_C738_8E38_1C70_78F0_F0F0_C3E0_07C0_1F80_FF00_F800_0000_0000_0000))
    bit5(.Z(z5),.I7(a[3]),.I6(a[2]),.I5(a[1]),.I4(a[0]),.I3(b[3]),.I2(b[2]),.I1(b[1]),.I0(b[0]));
    
    GTP_LUT8#(.INIT(256'h5554_AB54_5294_B4B4_4924_936C_66CC_CCCC_3398_C738_1C70_F0F0_07C0_FF00_0000_0000))
    bit4(.Z(z4),.I7(a[3]),.I6(a[2]),.I5(a[1]),.I4(a[0]),.I3(b[3]),.I2(b[2]),.I1(b[1]),.I0(b[0]));
    
    GTP_LUT8#(.INIT(256'h01FE_1E1E_39C6_6666_6D92_5A5A_55AA_AAAA_AB54_B4B4_936C_CCCC_C738_F0F0_FF00_0000))
    bit3(.Z(z3),.I7(a[3]),.I6(a[2]),.I5(a[1]),.I4(a[0]),.I3(b[3]),.I2(b[2]),.I1(b[1]),.I0(b[0]));
    
    GTP_LUT8#(.INIT(256'h1E1E_6666_5A5A_AAAA_B4B4_CCCC_F0F0_0000_1E1E_6666_5A5A_AAAA_B4B4_CCCC_F0F0_0000))
    bit2(.Z(z2),.I7(a[3]),.I6(a[2]),.I5(a[1]),.I4(a[0]),.I3(b[3]),.I2(b[2]),.I1(b[1]),.I0(b[0]));
    
    GTP_LUT8#(.INIT(256'h6666_AAAA_CCCC_0000_6666_AAAA_CCCC_0000_6666_AAAA_CCCC_0000_6666_AAAA_CCCC_0000))
    bit1(.Z(z1),.I7(a[3]),.I6(a[2]),.I5(a[1]),.I4(a[0]),.I3(b[3]),.I2(b[2]),.I1(b[1]),.I0(b[0]));
    
    GTP_LUT8#(.INIT(256'hAAAA_0000_AAAA_0000_AAAA_0000_AAAA_0000_AAAA_0000_AAAA_0000_AAAA_0000_AAAA_0000))
    bit0(.Z(z0),.I7(a[3]),.I6(a[2]),.I5(a[1]),.I4(a[0]),.I3(b[3]),.I2(b[2]),.I1(b[1]),.I0(b[0]));
    always @(posedge clk)begin		//
        c <= {z7,z6,z5,z4,z3,z2,z1,z0};
    end

    
    
endmodule

