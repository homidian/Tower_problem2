module alignment_net_tb();
    parameter DATA_WIDTH = 8;

    reg [DATA_WIDTH-1:0] InBuf;
    reg reverse;
    reg [2:0] align_start;
    wire [DATA_WIDTH-1:0] OutBuf;


    alignment_network #(.DATA_WIDTH(8),.WORD_WIDTH(1)) dut(
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
        InBuf = 8'h12;
        align_start = 3'b000;
        #5 align_start = 0;
        #60 reverse = 1;
        #60 $finish;
    end

endmodule
