module alignment_net_tb();
    parameter DATA_WIDTH = 64;

    reg [DATA_WIDTH-1:0] InBuf;
    reg reverse;
    reg [2:0] align_start;
    wire [DATA_WIDTH-1:0] OutBuf;


    alignment_network dut(
        InBuf,
        reverse,
        align_start,
        OutBuf
    );

    always #5 align_start = align_start + 1;
    initial begin
        $dumpfile("alignment_net_tb.vcd");
        $dumpvars(0,alignment_net_tb);
        reverse = 0;
        InBuf = 64'h0123456789ABCDEF;
        align_start = 8'h01;
        #5 align_start = 0;
        #60 reverse = 1;
        #60 $finish;
    end

endmodule
