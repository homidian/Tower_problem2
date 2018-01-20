
module Alignment_Network_tb();
    parameter DATA_WIDTH = 64;

    reg [DATA_WIDTH-1:0] InBuf;
    reg [DATA_WIDTH/8-1:0] InBuf_Enable;
    //reg [DATA_WIDTH/8-1:0] InBuf_Read;
    reg reverse;
    reg [2:0] align_start;
    wire [DATA_WIDTH-1:0] OutBuf;
    //wire OutBuf_Write;
        reg [DATA_WIDTH/8-1:0] Align_ReadEn_In;
        wire [DATA_WIDTH/8-1:0] Align_ReadEn_Out;

    Alignment_Network #(64) dut(
        InBuf,
        reverse,
        align_start,
        OutBuf,
);

    always #5 align_start = align_start + 1;
    initial begin
      $dumpfile("Alignment_Network_tb.vcd");
      $dumpvars(0,Alignment_Network_tb);
        reverse = 0;
        InBuf = 64'h0123456789ABCDEF;
        Align_ReadEn_In = 128;
        InBuf_Enable = 255;
        align_start = 8'h01;
        #5 align_start = 0;
//        #5 align_start = 3;
//        #5 align_start = 4;
//        #5 align_start = 8;
//        #5 align_start = 7;
        #100 $finish;
    end

endmodule
