module alignment_network(
    InBuf,
    reverse,
    align_start,
    OutBuf
);
    // constants
    parameter DATA_WIDTH = 64;
    parameter WORD_WIDTH = 8;

    input [DATA_WIDTH-1:0] InBuf;
    input reverse;
    input [2:0] align_start;
    //input [clog2(DATA_WIDTH/WORD_WIDTH)-1:0] align_start;
    output [DATA_WIDTH-1:0] OutBuf;

    wire [2:0] sel;

    wire [WORD_WIDTH-1:0] InBuf_data [DATA_WIDTH/WORD_WIDTH-1:0];
    wire [WORD_WIDTH-1:0] OutBuf_data [DATA_WIDTH/WORD_WIDTH-1:0];

    assign sel = reverse ? (DATA_WIDTH/WORD_WIDTH) - align_start : align_start;

    genvar i;
    generate
        for (i = 0; i < DATA_WIDTH/WORD_WIDTH; i = i + 1)
        begin
            assign  InBuf_data[i] = InBuf[((WORD_WIDTH)*(i+1)-1):(WORD_WIDTH)*i];

            mux8to1 #(.DATA_WIDTH(WORD_WIDTH), .SEL_WIDTH(3)) MUX_Data(
                .Out(OutBuf_data[i]),
                //.Out(OutBuf[((DATA_WIDTH/8)*(i+1)-1):(DATA_WIDTH/8)*i]),
                .Sel(sel),
                .In1(InBuf_data[(i)&3'b111]),
                .In2(InBuf_data[(i+1)&3'b111]),
                .In3(InBuf_data[(i+2)&3'b111]),
                .In4(InBuf_data[(i+3)&3'b111]),
                .In5(InBuf_data[(i+4)&3'b111]),
                .In6(InBuf_data[(i+5)&3'b111]),
                .In7(InBuf_data[(i+6)&3'b111]),
                .In8(InBuf_data[(i+7)&3'b111])
                );

            assign OutBuf[((WORD_WIDTH)*(i+1)-1):(WORD_WIDTH)*i] = OutBuf_data[i];
        end
    endgenerate
endmodule


module mux8to1( Out,
      Sel,
      In1,
      In2,
      In3,
      In4,
      In5,
      In6,
      In7,
      In8
);
    parameter DATA_WIDTH = 8;
    parameter SEL_WIDTH = 3;

    input [DATA_WIDTH-1:0]  In1, In2, In3, In4, In5, In6, In7, In8;

    input [SEL_WIDTH-1:0] Sel; //The three bit selection line
    output [DATA_WIDTH-1:0] Out; //The single 8-bit output line of the Mux

    reg [DATA_WIDTH-1:0] Out;

    //Check the state of the input lines

    always @ (In1 or In2 or In3 or In4 or In5 or In6 or In7 or In8 or Sel)
    begin
     case (Sel)
      3'b000 : Out = In1;
      3'b001 : Out = In2;
      3'b010 : Out = In3;
      3'b011 : Out = In4;
      3'b100 : Out = In5;
      3'b101 : Out = In6;
      3'b110 : Out = In7;
      3'b111 : Out = In8;
      default : Out = 8'bx;
      //If input is undefined then output is undefined
     endcase
    end
endmodule

module DeMux1to8(in,
                sel,
                out
);
input in;
input [2:0] sel;
output reg [7:0] out =0;

    always @ (in or sel)
    begin
     case (sel)
      3'b000 : out = in;
      3'b001 : out = in << 1;
      3'b010 : out = in << 2;
      3'b011 : out = in << 3;
      3'b100 : out = in << 4;
      3'b101 : out = in << 5;
      3'b110 : out = in << 6;
      3'b111 : out = in << 7;
      default : out = 8'bx;
      //If input is undefined then output is undefined
     endcase
    end
endmodule



// module alignment_net_tb();
//     parameter DATA_WIDTH = 64;
//
//     reg [DATA_WIDTH-1:0] InBuf;
//     reg reverse;
//     reg [2:0] align_start;
//     wire [DATA_WIDTH-1:0] OutBuf;
//
//
//     alignment_network dut(
//         InBuf,
//         reverse,
//         align_start,
//         OutBuf
//     );
//
//     always #5 align_start = align_start + 1;
//     initial begin
//         $dumpfile("alignment_net_tb.vcd");
//         $dumpvars(0,alignment_net_tb);
//         reverse = 0;
//         InBuf = 64'h0123456789ABCDEF;
//         align_start = 8'h01;
//         #5 align_start = 0;
//         #60 reverse = 1;
//         #60 $finish;
//     end
//
// endmodule
